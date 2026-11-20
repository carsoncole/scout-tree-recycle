# Preview all emails at http://localhost:3000/rails/mailers/users_mailer
class UsersMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/users_mailer/account_created
  def account_created
    user = User.take || User.new(email: "new-user@example.com", role: "user", password: SecureRandom.base58(32))

    UsersMailer.account_created(user)
  end
end
