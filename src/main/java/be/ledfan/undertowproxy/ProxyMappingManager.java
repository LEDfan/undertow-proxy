package be.ledfan.undertowproxy;

import io.undertow.server.HttpHandler;
import io.undertow.server.handlers.PathHandler;
import io.undertow.server.handlers.ResponseCodeHandler;
import io.undertow.server.handlers.proxy.LoadBalancingProxyClient;
import io.undertow.server.handlers.proxy.ProxyHandler;
import org.springframework.stereotype.Component;

import java.net.URI;

@Component
public class ProxyMappingManager {

    private static final String PROXY_INTERNAL_ENDPOINT = "/proxy_endpoint";

    private PathHandler pathHandler;

    public synchronized HttpHandler createHttpHandler(HttpHandler defaultHandler) {
        if (pathHandler == null) {
            pathHandler = new PathHandler(defaultHandler);
        }
        return pathHandler;
    }

    @SuppressWarnings("deprecation")
    public synchronized void addMapping(String mapping, URI target) {
        if (pathHandler == null)
            throw new IllegalStateException("Cannot change mappings: web server is not yet running.");

        LoadBalancingProxyClient proxyClient = new LoadBalancingProxyClient();
        proxyClient.addHost(target);
        proxyClient.setMaxQueueSize(100);

        String path = PROXY_INTERNAL_ENDPOINT + "/" + mapping;
        pathHandler.addPrefixPath(path, new ProxyHandler(proxyClient, ResponseCodeHandler.HANDLE_404));
    }

}
