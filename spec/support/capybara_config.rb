WebMock.disable_net_connect!(allow: [
                               "127.0.0.1",
                               "localhost",
                               "www.rdv-solidarites-test.localhost",
                               "chromedriver.storage.googleapis.com", # Autorise à télécharger le binaire chromedriver pour l'exécution de la CI
                             ])

Capybara.register_driver :selenium do |app|
  chrome_bin = ENV.fetch("GOOGLE_CHROME_SHIM", nil)
  binary = chrome_bin if chrome_bin
  browser_options = Selenium::WebDriver::Chrome::Options.new(
    # these args seem to reduce test flakyness
    args: %w[headless no-sandbox disable-gpu disable-dev-shm-usage window-size=1500,1000],
    "goog:loggingPrefs": { browser: "ALL" },
    binary: binary
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: browser_options
  )
end

Capybara.javascript_driver = :selenium

Capybara.configure do |config|
  port = 9887 + ENV["TEST_ENV_NUMBER"].to_i
  config.app_host = "http://www.rdv-solidarites-test.localhost:#{port}"
  # config.asset_host = "http://localhost:#{port}"  # for screenshots
  config.server_host = "www.rdv-solidarites-test.localhost"
  config.server_port = port
  config.javascript_driver = :selenium
  config.server = :puma, { Silent: true }
  config.disable_animation = true

  # This is necessary when using Selenium + custom .localhost domain.
  # See: https://stackoverflow.com/a/63973323/2864020
  config.always_include_port = true
end

RSpec.configure do |config|
  config.after(:each, js: true) do |example|
    next unless example.exception # only write logs for failed tests

    FileUtils.mkdir_p "tmp/capybara"
    %i[browser driver].each do |source|
      errors = Capybara.page.driver.browser.logs.get(source)
      fp = "tmp/capybara/chrome.#{example.full_description.parameterize}.#{source}.log"
      File.open(fp, "w") do |f|
        f << "// empty logs" if errors.empty?
        errors.each do |e|
          f << "#{e.timestamp} [#{e.level}]: #{e.message}"
        end
        f << "\n"
      end
    end
  end
end

def expect_page_to_be_axe_clean(path)
  visit path # TODO: supprimer en même temps que app/javascript/components/header_tooltip.js
  # Le premier visit permet d'afficher le tooltip du header, et faire qu'il n'apparaisse pas la deuxieme fois
  visit path
  expect(page).to have_current_path(path)
  expect(page).to be_axe_clean
end
