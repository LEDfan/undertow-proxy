package be.ledfan.undertowproxy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.web.embedded.undertow.UndertowServletWebServerFactory;
import org.springframework.boot.web.server.PortInUseException;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.event.EventListener;
import org.springframework.web.filter.FormContentFilter;

import javax.annotation.PostConstruct;
import javax.inject.Inject;
import java.net.URI;
import java.util.Properties;

@SpringBootApplication
@ComponentScan("be.ledfan")
public class Application {

	@Inject
	private ProxyMappingManager mappingManager;

	public static void main(String[] args) {
		SpringApplication app = new SpringApplication(Application.class);

		setDefaultProperties(app);

		try {
			app.setLogStartupInfo(false);
			app.run(args);
		} catch (Exception e) {
			// Workaround for bug in UndertowEmbeddedServletContainer.start():
			// If undertow.start() fails, started remains false which prevents undertow.stop() from ever being called.
			// Undertow's (non-daemon) XNIO worker threads will then prevent the JVM from exiting.
			if (e instanceof PortInUseException) System.exit(-1);
		}
	}

	@PostConstruct
	public void init() {
	}

	@EventListener
	public void applicationReady(ApplicationReadyEvent e) {
		mappingManager.addMapping("demo", URI.create("http://localhost:3838"));
	}

	@Bean
	public UndertowServletWebServerFactory servletContainer() {
		UndertowServletWebServerFactory factory = new UndertowServletWebServerFactory();
		factory.addDeploymentInfoCustomizers(info -> {
			info.setPreservePathOnForward(false); // required for the /api/route/{id}/ endpoint to work properly
			info.addInnerHandlerChainWrapper(defaultHandler -> mappingManager.createHttpHandler(defaultHandler));
		});
		factory.setPort(8080);
		return factory;
	}

	// Disable specific Spring filters that parse the request body, preventing it from being proxied.
	@Bean
	public FilterRegistrationBean<FormContentFilter> registration2(FormContentFilter filter) {
		FilterRegistrationBean<FormContentFilter> registration = new FilterRegistrationBean<>(filter);
		registration.setEnabled(false);
		return registration;
	}

	private static void setDefaultProperties(SpringApplication app) {
		Properties properties = new Properties();

		// disable multi-part handling by Spring. We don't need this anywhere in the application.
		// When enabled this will cause problems when proxying file-uploads to the shiny apps.
		properties.put("spring.servlet.multipart.enabled", "false");

		// disable logging of requests, since this reads part of the requests and therefore undertow is unable to correctly handle those requests
		properties.put("logging.level.org.springframework.web.servlet.DispatcherServlet", "INFO");

		app.setDefaultProperties(properties);
	}

}