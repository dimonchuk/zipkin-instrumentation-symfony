build:
	./build.sh $(SYMFONY_VERSION)

run-server:
	php ./test-app/bin/console server:run

run-zipkin:
	docker run -d -p 9411:9411 openzipkin/zipkin
