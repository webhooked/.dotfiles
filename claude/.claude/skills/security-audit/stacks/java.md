# Java / JVM — Audit Patterns

Covers Spring Boot, Spring MVC, Jakarta EE, JAX-RS, JDBC, JPA/Hibernate, plain servlets. Kotlin idioms map similarly.

## A01 Broken Access Control

- **Spring Security** — `@PreAuthorize("permitAll()")` on sensitive endpoints; missing `@PreAuthorize` / `@Secured` on `@RestController` methods.
- **`HttpSecurity.authorizeRequests().anyRequest().permitAll()`** in `SecurityFilterChain`.
- **CORS** — `CorsConfiguration.setAllowedOrigins(List.of("*"))` with `setAllowCredentials(true)`.
- **IDOR** — `repository.findById(id)` without checking the owner; should be `findByIdAndOwner(id, currentUser)`.
- **`response.sendRedirect(request.getParameter("returnUrl"))`** — open redirect.

## A02 Security Misconfiguration

- **`application.properties` / `application.yml`**:
  - `server.error.include-stacktrace=always`
  - `server.error.include-message=always`
  - `management.endpoints.web.exposure.include=*` — exposes Actuator including `/env`, `/heapdump`.
  - `spring.h2.console.enabled=true` in production.
- **`@CrossOrigin(origins = "*", allowCredentials = "true")`** — same invalid combo as Express.
- **`SpringApplication.setDefaultProperties` with `debug=true`**.
- **Tomcat manager / Spring Boot Admin** exposed without auth.

## A03 Software Supply Chain Failures

- **Maven / Gradle dependencies with version ranges** (`[1.0,)`).
- **Custom Maven repositories over HTTP**.
- **Gradle `apply from: 'https://...'`** pulling build scripts from external URLs.

## A04 Cryptographic Failures

- **`java.util.Random`** for tokens / passwords / IVs — must be `SecureRandom`.
- **`MessageDigest.getInstance("MD5" | "SHA-1")`** for password hashing.
- **`Cipher.getInstance("AES")`** — defaults to `AES/ECB/PKCS5Padding`. ECB mode.
- **`Cipher.getInstance("AES/CBC/PKCS5Padding")` with hardcoded IV**.
- **`PBEKeySpec` with iteration count < 100,000**.
- **Hardcoded `Key key = new SecretKeySpec("hardcoded".getBytes(), "AES")`**.
- **`SSLContext` with custom `TrustManager` that has empty `checkServerTrusted`** — disables TLS validation.
- **`HostnameVerifier` returning `true`** unconditionally.

## A05 Injection

### SQL injection
- **JDBC** — `Statement.executeQuery("SELECT * FROM x WHERE id = " + id)`. Must use `PreparedStatement` with `?` placeholders.
- **JPA / Hibernate** — `entityManager.createQuery("FROM User u WHERE u.name = '" + name + "'")` — JPQL injection. Use `:named` params.
- **Spring Data JPA `@Query(nativeQuery = true)`** with `?#{#x}` or `:x` is safe; with string concatenation is not.
- **`JdbcTemplate.queryForObject("SELECT ... WHERE x = '" + x + "'", ...)`** vs the parameterized overload.

### Command injection
- **`Runtime.getRuntime().exec(cmdString)`** with concatenated user input. Use the `String[]` overload.
- **`ProcessBuilder("sh", "-c", "cmd " + user)`**.

### LDAP injection
- **`DirContext.search(base, "(uid=" + user + ")", ...)`** — escape with `LdapName` or use param-binding APIs.

### Template injection
- **Thymeleaf** `th:utext` with user input.
- **FreeMarker** `Template.process` where the template **string** is user-controlled — RCE via `freemarker.template.utility.Execute`.
- **Velocity** with user-controlled templates.

### Path traversal
- **`new File(baseDir, userInput)`** — does not prevent `..` traversal.
- **`Files.copy(Paths.get(userInput), ...)`** — verify within base via `Path.toRealPath` + prefix check.

### XXE
- **`DocumentBuilderFactory.newInstance()`** without disabling DTDs:
  ```java
  factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
  ```
- **`SAXParserFactory`, `XMLInputFactory`, `TransformerFactory`** — all share the XXE story. Look for the absence of the hardening features.
- **`Unmarshaller.unmarshal(xml)`** without XXE protection on the underlying parser.

### Spring Expression / SpEL
- **`Expression exp = parser.parseExpression(userInput); exp.getValue(...);`** — SpEL injection → RCE.
- **`@PreAuthorize("...")` with interpolated user input** (rare).

## A06 Insecure Design

- **Spring `ResponseEntity.redirect(URI.create(request.getParameter("u")))`** — same as direct redirect.
- **Token generation via `UUID.randomUUID().toString()`** is OK (random UUIDs are unguessable). Via `new UUID(timeBased())` is **not**.

## A07 Authentication Failures

- **`jjwt` `parser().setSigningKey(key).parseClaimsJws(jwt)`** is OK; **`parseClaimsJwt`** (no signature verification) is not.
- **`io.jsonwebtoken.Jwts.parser()`** without `setSigningKey` on a public endpoint.
- **Spring Security `BCryptPasswordEncoder(4)`** — log rounds too low.
- **Session fixation** — Spring Security has `.sessionFixation().migrateSession()` by default; flag if explicitly disabled (`.sessionFixation().none()`).
- **`@Configuration` that disables CSRF globally** (`http.csrf().disable()`) for cookie-based auth.

## A08 Software or Data Integrity Failures

Java deserialization is the canonical RCE pattern:

- **`ObjectInputStream.readObject()`** on attacker-influenced bytes — RCE via gadget chains (`commons-collections`, `spring-aop`, etc.).
- **`XMLDecoder.readObject()`** — RCE.
- **`SnakeYAML` `Yaml.load`** without `SafeConstructor` — RCE.
- **`Jackson` with `enableDefaultTyping()` / `@JsonTypeInfo(use = Id.CLASS)`** — polymorphic deserialization RCE.
- **`Kryo` with `setRegistrationRequired(false)`**.
- **`Hessian` / `Burlap`** deserialization on untrusted bytes.
- **`RMI`** endpoints accepting arbitrary class names.

## A10 Mishandling of Exceptional Conditions

- **`catch (Exception e) { log.error(...); }`** around auth checks, then the method continues.
- **Spring `@ExceptionHandler`** that returns 200 OK for security exceptions instead of 401/403.
- **`AuthenticationProvider.authenticate`** implementations that return an authenticated token on exception.

## Common files / locations to prioritize

- `pom.xml`, `build.gradle(.kts)`
- `application.properties`, `application.yml`, `application-*.yml`
- `src/main/java/**/config/**SecurityConfig.java`
- `src/main/java/**/controller/**`
- `src/main/java/**/repository/**` (raw queries)
- `WEB-INF/web.xml` (legacy servlet auth)
