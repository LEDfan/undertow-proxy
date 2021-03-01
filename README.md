# Undertow Proxy bug

This repository contains all Java code and dependencies to reproduce a problem when using Undertow as Proxy server.

## Setup steps

1. Clone the repo
   ```
   git clone git@github.com:LEDfan/undertow-proxy.git
   cd undertow-proxy
   ```
2. Compile the code
   ```
   mvn clean -U package install -DskipTests
   ```
3. Build the Docker image of the application that will be used as proxy target. This takes about half on hour on my machine. Instead of building the image yourself, you can also use the `ledfan/undertow-proxy-target` image.
   ```
   cd proxy-target/
   docker build -t proxy-target .
   ```
4. Start the Proxy target
   ```
   docker run -p 3838:3838 proxy-target
   # or use the pre-built image from Docker hub:
   docker run -p 3838:3838 ledfan/undertow-proxy-target 
   ```
5. Start the Java application (i.e. the proxy)
   ```
   java -jar target/undertowproxy-0.1.0-SNAPSHOT-exec.jar 
   ```

## Steps to reproduce

1. Open `http://localhost:8080/proxy_endpoint/demo/` in a browser
2. Open the network tools and make sure both the network tab and console is visible
3. Hard-refresh the page a few times, using Ctrl+Shift+R, in order to reproduce the bug I have to refresh between 10 and 20 times.

Note: it seems that the bug appears more often in Chrome than in Firefox.

## Expected results

1. every time you load the page, it is properly loaded and all resources are properly loaded

## Actual results

1. sometimes a resource (JS or CSS file) fails to load and returns a 503
2. a message is logged:
   ```
   2021-03-01 11:27:50.560 ERROR 41643 --- [   XNIO-1 I/O-6] io.undertow.proxy                        : UT005028: Proxy request to /proxy_endpoint/demo/highcharts-8.1.2/modules/bullet.js failed

   java.io.IOException: UT001000: Connection closed
   at io.undertow.client.http.HttpClientConnection$ClientReadListener.handleEvent(HttpClientConnection.java:581) [undertow-core-2.2.4.Final.jar!/:2.2.4.Final]
   at io.undertow.client.http.HttpClientConnection$ClientReadListener.handleEvent(HttpClientConnection.java:516) [undertow-core-2.2.4.Final.jar!/:2.2.4.Final]
   at org.xnio.ChannelListeners.invokeChannelListener(ChannelListeners.java:92) [xnio-api-3.8.0.Final.jar!/:3.8.0.Final]
   at org.xnio.conduits.ReadReadyHandler$ChannelListenerHandler.readReady(ReadReadyHandler.java:66) [xnio-api-3.8.0.Final.jar!/:3.8.0.Final]
   at org.xnio.nio.NioSocketConduit.handleReady(NioSocketConduit.java:89) [xnio-nio-3.8.0.Final.jar!/:3.8.0.Final]
   at org.xnio.nio.WorkerThread.run(WorkerThread.java:591) [xnio-nio-3.8.0.Final.jar!/:3.8.0.Final]
   ```