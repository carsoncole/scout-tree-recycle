class Router
    def initialize(obj)
      @obj = obj
    end

    def location
      @obj
    end

    def route!
      return if location.is_manually_routed?
      return unless location.geocoded?
      location.update_columns(was_automatically_routed: true)
      Route.ordered.each do |z|
        if z.polygon? && z.contains?(location.latitude, location.longitude)
          assign_route!(z.id)
          break
        end
        # puts z.coordinates
        # distance_to_new_route = location.distance_to(z.coordinates)
        # # puts distance_to_new_route
        # if (location.route && location.distance_to_route > distance_to_new_route) || location.route.nil?
        #   # location.route_id = z.id
        #   @distance_to_route = distance_to_new_route
        #   @route_id = z.id
        # end
      end
      location.route
    end

    # update_columns skips the belongs_to counter cache. Adjust the old and
    # new route counts here so Routes keeps a real reservation total.
    def assign_route!(route_id)
      previous_route_id = location.route_id
      location.transaction do
        location.update_columns(route_id: route_id, status: "pending_pickup")
        next if previous_route_id == route_id

        Route.decrement_counter(:reservations_count, previous_route_id) if previous_route_id.present?
        Route.increment_counter(:reservations_count, route_id)
      end
    end
    private :assign_route!

    def zone!
      return unless location.is_zoned?
      location.zone_id = nil
      return unless location.geocoded?
      Zone.ordered.each do |z|
        # puts z.coordinates
        distance_to_new_zone = location.distance_to(z.coordinates)
        # puts distance_to_new_zone
        if (location.zone && location.distance_to_zone > distance_to_new_zone) || location.zone.nil?
          location.zone_id = z.id
          location.distance_to_zone = distance_to_new_zone
        end
      end
    end
end
