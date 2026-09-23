# Item CRUD service

A small Spring Boot REST service for an `Item` domain, built for a live CRUD demo. It has a controller, transactional service, Spring Data JPA repository, request validation, consistent JSON errors, and an embedded H2 database. No external services or credentials are needed.

## Run

Requires Java 17 or newer and Maven 3.6.3 or newer.

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn clean test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn spring-boot:run
```

These commands use the Homebrew Java 17 installation on Adam's Mac. On another machine, use its installed JDK in `JAVA_HOME`. The API listens at `http://localhost:8080`. Data is in memory and resets when the application restarts.

## Demo in VS Code

Open this folder in VS Code. The recommended Java and REST Client extensions provide Java run/debug support and `Send Request` links in [items.http](items.http). On Adam's Mac, choose **Terminal > Run Task > Run Items API** and wait for `Started ItemsApplication`; then open `items.http` and click **Send Request** above each request from top to bottom. The create response supplies the ID used by the read, update, and delete requests. The last two requests show the JSON `404` and validation `400` responses. The **Test Items API** task runs the integration tests; **Run and Debug > Debug Items API** is available for breakpoints.

If port 8080 is already in use, stop the other process before starting this demo. The in-memory H2 database needs no installation and starts empty each time the app starts.

## Demo the API

In another terminal:

```sh
curl -i http://localhost:8080/items

curl -i -X POST http://localhost:8080/items \
  -H 'Content-Type: application/json' \
  -d '{"name":"Keyboard","description":"Compact","price":49.99,"quantity":3}'

curl -i http://localhost:8080/items/1

curl -i -X PUT http://localhost:8080/items/1 \
  -H 'Content-Type: application/json' \
  -d '{"name":"Wireless Keyboard","description":"Compact","price":54.99,"quantity":2}'

curl -i -X DELETE http://localhost:8080/items/1
curl -i http://localhost:8080/items/1
```

The POST response is `201 Created` with a `Location: /items/{id}` header. A successful DELETE is `204 No Content`. Missing items return `404`; invalid or malformed JSON returns `400` with a JSON error. Use the ID in the POST response if it is not `1`.

| Method | Path | Result |
| --- | --- | --- |
| GET | `/items` | List all items, sorted by ID |
| GET | `/items/{id}` | Read one item |
| POST | `/items` | Create an item |
| PUT | `/items/{id}` | Replace its editable fields |
| DELETE | `/items/{id}` | Delete an item |

Request fields: `name` (required, max 120 characters), `description` (optional, max 500), `price` (required, greater than zero, at most two decimal places), and `quantity` (required, zero or greater). The server generates the `id`.

## Build a runnable JAR

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn clean package
/opt/homebrew/opt/openjdk@17/bin/java -jar target/spring-items-service-1.0.0.jar
```

The integration tests exercise every endpoint, persistence across requests, validation, malformed JSON, and missing-item responses. The database is intentionally ephemeral for a self-contained demo; production deployment would require a persistent database, migrations, and access controls.
