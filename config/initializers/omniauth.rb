require "omniauth/strategies/franceconnect"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch("GITHUB_APP_ID", nil), ENV.fetch("GITHUB_APP_SECRET", nil), scope: "user:email"

  if Domain::RDV_SOLIDARITES.azure_application_client_id
    provider(:microsoft_graph,
             Domain::RDV_SOLIDARITES.azure_application_client_id,
             Domain::RDV_SOLIDARITES.azure_application_client_secret,
             scope: %w[offline_access openid email profile User.Read Calendars.ReadWrite])
  end

  # TODO : have two different names for the different oauth providers
  # if Domain::RDV_AIDE_NUMERIQUE.azure_application_client_id
  #   provider(:microsoft_graph,
  #            Domain::RDV_AIDE_NUMERIQUE.azure_application_client_id,
  #            Domain::RDV_AIDE_NUMERIQUE.azure_application_client_secret,
  #            scope: %w[offline_access openid email profile User.Read Calendars.ReadWrite])
  # end

  provider(
    :franceconnect,
    name: :franceconnect,
    scope: %i[email openid birthdate birthplace given_name family_name birthcountry],
    issuer: "https://#{ENV.fetch('FRANCECONNECT_HOST', nil)}",
    client_options: {
      identifier: ENV.fetch("FRANCECONNECT_APP_ID", nil),
      secret: ENV.fetch("FRANCECONNECT_APP_SECRET", nil),
      redirect_uri: "#{ENV.fetch('HOST', nil)}/omniauth/franceconnect/callback",
      host: ENV.fetch("FRANCECONNECT_HOST", nil),
    }
  )

  on_failure do |env|
    http_host = env["HTTP_HOST"]
    provider = env["omniauth.error.strategy"].class.name.demodulize
    error_type = env["omniauth.error.type"]
    error = env["omniauth.error"]

    crumb = Sentry::Breadcrumb.new(
      message: "Omniauth env values",
      data: {
        http_host: http_host,
        provider: provider,
        error: error,
        error_type: error_type,
        full_env: env.transform_values { |value| value.is_a?(String) ? value : value.inspect },
      }
    )
    Sentry.add_breadcrumb(crumb)

    Sentry.capture_message("Omniauth for #{provider} failed on #{http_host}: #{error}", fingerprint: [provider, http_host])

    OmniauthCallbacksController.action(:failure).call(env)
  end
end
