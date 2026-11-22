class Admin::DataResetsController < Admin::BaseController
  before_action :require_admin_access

  def create
    scope = params.dig(:data_reset, :scope).to_s

    # Loading sample data is additive: it needs no typed confirmation, and it
    # runs in a background job because it takes long enough to time out the
    # request. The outcome is recorded in the System Logs with the "job" type.
    if scope == "sample_data"
      LoadSampleDataJob.perform_later(user: Current.user)
      return redirect_to admin_data_path,
        notice: "Sample data load queued. Check the System Logs for results."
    end

    unless DataReset::SCOPES.include?(scope)
      return redirect_to admin_data_path, alert: "Unknown data reset action."
    end

    # Destructive actions require a typed confirmation word, validated server-side.
    if DataReset::CONFIRMATION_WORDS.key?(scope) && !DataReset.confirmed?(scope, params[:confirmation])
      return redirect_to admin_data_path,
        alert: "Type #{DataReset.confirmation_word(scope)} to confirm this destructive action."
    end

    result = DataReset.new(scope: scope, user: Current.user).perform!

    if result.signed_out
      # The full reset deleted every user, session, and setting. Clear the
      # sign-in cookie and land on first-run setup to create new ones.
      cookies.delete(:session_id)
      redirect_to new_admin_setting_path,
        notice: "All data has been reset to defaults. Default email templates were reloaded. Complete the initial setup to continue."
    else
      redirect_to admin_data_path, notice: reset_notice(result)
    end
  rescue StandardError => e
    Rails.error.report(e, handled: true, severity: :error, context: { scope: scope, user: Current.user&.email })
    redirect_to admin_data_path, alert: "The data reset could not be completed: #{e.message}"
  end

  private

  def require_admin_access
    unless Current.user.admin?
      redirect_to admin_data_path, alert: "You are not authorized to delete or reset data."
    end
  end

  def reset_notice(result)
    case result.scope
    when "reservations"
      deleted = result.deleted_count == 1 ? "1 reservation has" : "#{result.deleted_count} reservations have"
      "#{deleted} been deleted. Donations were kept but detached from their reservations."
    when "contacts"
      deleted = result.deleted_count == 1 ? "1 contact has" : "#{result.deleted_count} contacts have"
      "#{deleted} been deleted."
    else
      "Done."
    end
  end
end
