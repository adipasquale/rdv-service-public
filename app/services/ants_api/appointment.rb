module AntsApi
  class Appointment
    class ApiRequestError < StandardError; end

    attr_reader :application_id, :meeting_point, :appointment_date, :management_url

    def initialize(application_id:, meeting_point:, appointment_date:, management_url:, editor_comment: nil)
      @application_id = application_id
      @meeting_point = meeting_point
      @appointment_date = appointment_date
      @management_url = management_url
      @editor_comment = editor_comment
    end

    def to_request_params
      {
        application_id: application_id,
        meeting_point: meeting_point,
        appointment_date: appointment_date,
        management_url: management_url,
      }
    end

    def create
      request do
        Typhoeus.post(
          "#{ENV['ANTS_RDV_API_URL']}/appointments",
          params: to_request_params,
          headers: self.class.headers
        )
      end
    end

    def delete
      request do
        Typhoeus.delete(
          "#{ENV['ANTS_RDV_API_URL']}/appointments",
          params: to_request_params.except(:management_url),
          headers: self.class.headers
        )
      end
    end

    private

    def request(&block)
      self.class.request(&block)
    end

    class << self
      def find_by(application_id:, management_url:)
        appointment_data = load_appointments(application_id).find do |appointment|
          appointment["management_url"] == management_url
        end
        Appointment.new(application_id: application_id, **appointment_data.symbolize_keys) if appointment_data
      end

      def first(application_id:, timeout: nil)
        appointment_data = load_appointments(application_id, timeout: timeout).first
        Appointment.new(application_id: application_id, **appointment_data.symbolize_keys) if appointment_data
      end

      def headers
        {
          "Accept" => "application/json",
          "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
        }
      end

      def request(&block)
        response = block.call
        if response.failure?
          raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
        end

        response.body.empty? ? {} : JSON.parse(response.body)
      end

      private

      def load_appointments(application_id, timeout: nil)
        response_body = request do
          Typhoeus.get(
            "#{ENV['ANTS_RDV_API_URL']}/status",
            params: { application_ids: application_id },
            headers: headers,
            timeout: timeout
          )
        end

        response_body.fetch(application_id, {}).fetch("appointments", [])
      end
    end
  end
end
