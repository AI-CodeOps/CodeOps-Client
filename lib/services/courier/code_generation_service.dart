/// Client-side code generation service for the Courier module.
///
/// Generates equivalent HTTP client code in 12 programming languages from a
/// request configuration. Each language template handles all HTTP methods,
/// query parameters, custom headers, body types (JSON, form-data, urlencoded,
/// raw text, binary), authentication types, SSL verification, and timeouts.
library;

import '../../models/courier_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Request data models for code generation
// ─────────────────────────────────────────────────────────────────────────────

/// Body data extracted from the request builder for code generation.
class CodegenBody {
  /// The body type.
  final BodyType type;

  /// Raw content for JSON/XML/HTML/Text/YAML body types.
  final String rawContent;

  /// Form data key-value pairs (form-data and urlencoded).
  final Map<String, String> formData;

  /// GraphQL query string.
  final String graphqlQuery;

  /// GraphQL variables JSON string.
  final String graphqlVariables;

  /// Binary file name.
  final String binaryFileName;

  /// Creates a [CodegenBody].
  const CodegenBody({
    this.type = BodyType.none,
    this.rawContent = '',
    this.formData = const {},
    this.graphqlQuery = '',
    this.graphqlVariables = '',
    this.binaryFileName = '',
  });
}

/// Auth data extracted from the request builder for code generation.
class CodegenAuth {
  /// The auth type.
  final AuthType type;

  /// Bearer token value.
  final String bearerToken;

  /// Bearer token prefix (default "Bearer").
  final String bearerPrefix;

  /// Basic auth username.
  final String basicUsername;

  /// Basic auth password.
  final String basicPassword;

  /// API key header name.
  final String apiKeyHeader;

  /// API key value.
  final String apiKeyValue;

  /// Where to add the API key: "header" or "query".
  final String apiKeyAddTo;

  /// Creates a [CodegenAuth].
  const CodegenAuth({
    this.type = AuthType.noAuth,
    this.bearerToken = '',
    this.bearerPrefix = 'Bearer',
    this.basicUsername = '',
    this.basicPassword = '',
    this.apiKeyHeader = '',
    this.apiKeyValue = '',
    this.apiKeyAddTo = 'header',
  });
}

/// Transport settings for code generation.
class CodegenSettings {
  /// Whether to verify SSL/TLS certificates.
  final bool sslVerify;

  /// Request timeout in milliseconds.
  final int timeoutMs;

  /// Whether to follow redirects.
  final bool followRedirects;

  /// Creates [CodegenSettings] with defaults.
  const CodegenSettings({
    this.sslVerify = true,
    this.timeoutMs = 30000,
    this.followRedirects = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Code Generation Service
// ─────────────────────────────────────────────────────────────────────────────

/// Generates HTTP client code snippets for 12 programming languages.
///
/// All generation happens client-side using Dart string templates. The server
/// API (`POST /courier/codegen/generate`) serves as a fallback for stored
/// requests or batch operations.
class CodeGenerationService {
  /// Creates a [CodeGenerationService].
  const CodeGenerationService();

  /// Generates code for the given request in [language].
  String generate({
    required CodeLanguage language,
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParams = const {},
    CodegenBody? body,
    CodegenAuth? auth,
    CodegenSettings settings = const CodegenSettings(),
  }) {
    final b = body ?? const CodegenBody();
    final a = auth ?? const CodegenAuth();

    // Merge auth headers/params into the maps.
    final effectiveHeaders = Map<String, String>.from(headers);
    final effectiveParams = Map<String, String>.from(queryParams);
    _applyAuth(a, effectiveHeaders, effectiveParams);

    // Add content-type header based on body type.
    _applyContentType(b, effectiveHeaders);

    return switch (language) {
      CodeLanguage.curl => _curl(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.pythonRequests => _python(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.javascriptFetch => _jsFetch(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.javascriptAxios => _jsAxios(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.javaHttpClient => _javaHttp(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.javaOkhttp => _javaOkhttp(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.csharpHttpClient => _csharp(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.go => _golang(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.ruby => _ruby(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.php => _php(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.swift => _swift(method, url, effectiveHeaders, effectiveParams, b, settings),
      CodeLanguage.kotlin => _kotlin(method, url, effectiveHeaders, effectiveParams, b, settings),
    };
  }

  /// Returns the file extension for [language].
  String fileExtension(CodeLanguage language) => switch (language) {
        CodeLanguage.curl => 'sh',
        CodeLanguage.pythonRequests => 'py',
        CodeLanguage.javascriptFetch || CodeLanguage.javascriptAxios => 'js',
        CodeLanguage.javaHttpClient || CodeLanguage.javaOkhttp => 'java',
        CodeLanguage.csharpHttpClient => 'cs',
        CodeLanguage.go => 'go',
        CodeLanguage.ruby => 'rb',
        CodeLanguage.php => 'php',
        CodeLanguage.swift => 'swift',
        CodeLanguage.kotlin => 'kt',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Auth + Content-Type helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _applyAuth(
    CodegenAuth auth,
    Map<String, String> headers,
    Map<String, String> params,
  ) {
    switch (auth.type) {
      case AuthType.bearerToken:
        final prefix = auth.bearerPrefix.isNotEmpty ? auth.bearerPrefix : 'Bearer';
        headers['Authorization'] = '$prefix ${auth.bearerToken}';
      case AuthType.basicAuth:
        headers['Authorization'] = 'Basic <base64(${auth.basicUsername}:${auth.basicPassword})>';
      case AuthType.apiKey:
        if (auth.apiKeyAddTo == 'query') {
          params[auth.apiKeyHeader] = auth.apiKeyValue;
        } else {
          headers[auth.apiKeyHeader] = auth.apiKeyValue;
        }
      default:
        break;
    }
  }

  void _applyContentType(CodegenBody body, Map<String, String> headers) {
    if (headers.containsKey('Content-Type')) return;
    switch (body.type) {
      case BodyType.rawJson:
        headers['Content-Type'] = 'application/json';
      case BodyType.rawXml:
        headers['Content-Type'] = 'application/xml';
      case BodyType.rawHtml:
        headers['Content-Type'] = 'text/html';
      case BodyType.rawText:
        headers['Content-Type'] = 'text/plain';
      case BodyType.rawYaml:
        headers['Content-Type'] = 'application/x-yaml';
      case BodyType.xWwwFormUrlEncoded:
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
      case BodyType.graphql:
        headers['Content-Type'] = 'application/json';
      default:
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // URL builder
  // ─────────────────────────────────────────────────────────────────────────

  String _buildUrl(String url, Map<String, String> params) {
    if (params.isEmpty) return url;
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return url.contains('?') ? '$url&$qs' : '$url?$qs';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body string helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _bodyContent(CodegenBody body) {
    return switch (body.type) {
      BodyType.rawJson || BodyType.rawXml || BodyType.rawHtml || BodyType.rawText || BodyType.rawYaml => body.rawContent,
      BodyType.graphql => '{"query": ${_escapeJsonStr(body.graphqlQuery)}${body.graphqlVariables.isNotEmpty ? ', "variables": ${body.graphqlVariables}' : ''}}',
      _ => '',
    };
  }

  bool _hasBody(CodegenBody body) =>
      body.type != BodyType.none && body.type != BodyType.binary;

  bool _isFormData(CodegenBody body) => body.type == BodyType.formData;

  bool _isUrlEncoded(CodegenBody body) => body.type == BodyType.xWwwFormUrlEncoded;

  String _escapeJsonStr(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
    return '"$escaped"';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // cURL
  // ─────────────────────────────────────────────────────────────────────────

  String _curl(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final buf = StringBuffer();
    final fullUrl = _buildUrl(url, params);
    buf.write("curl -X ${method.toUpperCase()} '$fullUrl'");

    for (final e in headers.entries) {
      buf.write(" \\\n  -H '${e.key}: ${e.value}'");
    }

    if (_isFormData(body)) {
      for (final e in body.formData.entries) {
        buf.write(" \\\n  -F '${e.key}=${e.value}'");
      }
    } else if (_isUrlEncoded(body)) {
      final encoded = body.formData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      buf.write(" \\\n  -d '$encoded'");
    } else if (body.type == BodyType.binary) {
      buf.write(" \\\n  --data-binary '@${body.binaryFileName}'");
    } else if (_hasBody(body)) {
      final content = _bodyContent(body);
      buf.write(" \\\n  -d '${content.replaceAll("'", "'\\''")}'");
    }

    if (!settings.sslVerify) buf.write(' \\\n  --insecure');
    if (settings.timeoutMs != 30000) {
      buf.write(' \\\n  --max-time ${(settings.timeoutMs / 1000).round()}');
    }
    if (!settings.followRedirects) buf.write(' \\\n  --max-redirs 0');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Python (Requests)
  // ─────────────────────────────────────────────────────────────────────────

  String _python(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final buf = StringBuffer('import requests\n\n');
    buf.writeln('url = "$url"');

    if (params.isNotEmpty) {
      buf.writeln('params = {');
      for (final e in params.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('}');
    }

    if (headers.isNotEmpty) {
      buf.writeln('headers = {');
      for (final e in headers.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('}');
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('data = {');
      for (final e in body.formData.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('}');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body);
      if (body.type == BodyType.rawJson || body.type == BodyType.graphql) {
        buf.writeln('json_data = $content');
      } else {
        buf.writeln('data = """$content"""');
      }
    }

    buf.write('\nresponse = requests.${method.toLowerCase()}(url');
    if (params.isNotEmpty) buf.write(', params=params');
    if (headers.isNotEmpty) buf.write(', headers=headers');

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.write(', data=data');
    } else if (_hasBody(body)) {
      if (body.type == BodyType.rawJson || body.type == BodyType.graphql) {
        buf.write(', json=json_data');
      } else {
        buf.write(', data=data');
      }
    }

    if (!settings.sslVerify) buf.write(', verify=False');
    if (settings.timeoutMs != 30000) {
      buf.write(', timeout=${(settings.timeoutMs / 1000).round()}');
    }
    if (!settings.followRedirects) buf.write(', allow_redirects=False');

    buf.writeln(')');
    buf.writeln('print(response.status_code)');
    buf.writeln('print(response.text)');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JavaScript (Fetch)
  // ─────────────────────────────────────────────────────────────────────────

  String _jsFetch(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();

    buf.writeln('const options = {');
    buf.writeln('  method: "${method.toUpperCase()}",');

    if (headers.isNotEmpty) {
      buf.writeln('  headers: {');
      for (final e in headers.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('  },');
    }

    if (_isFormData(body)) {
      buf.writeln('  body: new URLSearchParams({');
      for (final e in body.formData.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('  }),');
    } else if (_isUrlEncoded(body)) {
      final encoded = body.formData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      buf.writeln('  body: "$encoded",');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body);
      if (body.type == BodyType.rawJson || body.type == BodyType.graphql) {
        buf.writeln('  body: JSON.stringify($content),');
      } else {
        buf.writeln('  body: `$content`,');
      }
    }

    if (!settings.followRedirects) buf.writeln('  redirect: "manual",');

    buf.writeln('};');
    buf.writeln('');
    buf.writeln('fetch("$fullUrl", options)');
    buf.writeln('  .then(response => response.json())');
    buf.writeln('  .then(data => console.log(data))');
    buf.writeln('  .catch(error => console.error(error));');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JavaScript (Axios)
  // ─────────────────────────────────────────────────────────────────────────

  String _jsAxios(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final buf = StringBuffer('const axios = require("axios");\n\n');

    buf.writeln('const config = {');
    buf.writeln('  method: "${method.toLowerCase()}",');
    buf.writeln('  url: "$url",');

    if (params.isNotEmpty) {
      buf.writeln('  params: {');
      for (final e in params.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('  },');
    }

    if (headers.isNotEmpty) {
      buf.writeln('  headers: {');
      for (final e in headers.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('  },');
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('  data: new URLSearchParams({');
      for (final e in body.formData.entries) {
        buf.writeln('    "${e.key}": "${e.value}",');
      }
      buf.writeln('  }),');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body);
      if (body.type == BodyType.rawJson || body.type == BodyType.graphql) {
        buf.writeln('  data: $content,');
      } else {
        buf.writeln('  data: `$content`,');
      }
    }

    if (settings.timeoutMs != 30000) {
      buf.writeln('  timeout: ${settings.timeoutMs},');
    }
    if (!settings.followRedirects) {
      buf.writeln('  maxRedirects: 0,');
    }

    buf.writeln('};');
    buf.writeln('');
    buf.writeln('axios(config)');
    buf.writeln('  .then(response => console.log(response.data))');
    buf.writeln('  .catch(error => console.error(error));');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Java (HttpClient)
  // ─────────────────────────────────────────────────────────────────────────

  String _javaHttp(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln('import java.net.URI;');
    buf.writeln('import java.net.http.HttpClient;');
    buf.writeln('import java.net.http.HttpRequest;');
    buf.writeln('import java.net.http.HttpResponse;');
    buf.writeln('import java.time.Duration;');
    buf.writeln('');
    buf.writeln('HttpClient client = HttpClient.newBuilder()');
    buf.writeln('    .connectTimeout(Duration.ofMillis(${settings.timeoutMs}))');
    if (!settings.followRedirects) {
      buf.writeln('    .followRedirects(HttpClient.Redirect.NEVER)');
    } else {
      buf.writeln('    .followRedirects(HttpClient.Redirect.NORMAL)');
    }
    buf.writeln('    .build();');
    buf.writeln('');

    String bodyPublisher;
    if (_isFormData(body) || _isUrlEncoded(body)) {
      final encoded = body.formData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      bodyPublisher = 'HttpRequest.BodyPublishers.ofString("$encoded")';
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      bodyPublisher = 'HttpRequest.BodyPublishers.ofString("$content")';
    } else {
      bodyPublisher = 'HttpRequest.BodyPublishers.noBody()';
    }

    buf.writeln('HttpRequest request = HttpRequest.newBuilder()');
    buf.writeln('    .uri(URI.create("$fullUrl"))');
    buf.writeln('    .method("${method.toUpperCase()}", $bodyPublisher)');
    for (final e in headers.entries) {
      buf.writeln('    .header("${e.key}", "${e.value}")');
    }
    buf.writeln('    .build();');
    buf.writeln('');
    buf.writeln('HttpResponse<String> response = client.send(request,');
    buf.writeln('    HttpResponse.BodyHandlers.ofString());');
    buf.writeln('System.out.println(response.statusCode());');
    buf.writeln('System.out.println(response.body());');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Java (OkHttp)
  // ─────────────────────────────────────────────────────────────────────────

  String _javaOkhttp(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final buf = StringBuffer();
    buf.writeln('import okhttp3.*;');
    buf.writeln('import java.util.concurrent.TimeUnit;');
    buf.writeln('');
    buf.writeln('OkHttpClient client = new OkHttpClient.Builder()');
    buf.writeln('    .connectTimeout(${settings.timeoutMs}, TimeUnit.MILLISECONDS)');
    if (!settings.followRedirects) {
      buf.writeln('    .followRedirects(false)');
    }
    buf.writeln('    .build();');
    buf.writeln('');

    // Build URL with query params
    if (params.isNotEmpty) {
      buf.writeln('HttpUrl.Builder urlBuilder = HttpUrl.parse("$url").newBuilder();');
      for (final e in params.entries) {
        buf.writeln('urlBuilder.addQueryParameter("${e.key}", "${e.value}");');
      }
      buf.writeln('String requestUrl = urlBuilder.build().toString();');
    } else {
      buf.writeln('String requestUrl = "$url";');
    }
    buf.writeln('');

    // Build body
    final ct = headers['Content-Type'] ?? 'application/json';
    if (_isFormData(body)) {
      buf.writeln('RequestBody body = new FormBody.Builder()');
      for (final e in body.formData.entries) {
        buf.writeln('    .add("${e.key}", "${e.value}")');
      }
      buf.writeln('    .build();');
    } else if (_isUrlEncoded(body)) {
      buf.writeln('RequestBody body = new FormBody.Builder()');
      for (final e in body.formData.entries) {
        buf.writeln('    .add("${e.key}", "${e.value}")');
      }
      buf.writeln('    .build();');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      buf.writeln('MediaType mediaType = MediaType.parse("$ct");');
      buf.writeln('RequestBody body = RequestBody.create(mediaType, "$content");');
    }
    buf.writeln('');

    buf.writeln('Request request = new Request.Builder()');
    buf.writeln('    .url(requestUrl)');

    final m = method.toUpperCase();
    if (_hasBody(body) || _isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('    .method("$m", body)');
    } else if (m == 'GET' || m == 'HEAD') {
      buf.writeln('    .method("$m", null)');
    } else {
      buf.writeln('    .method("$m", RequestBody.create(null, new byte[0]))');
    }

    for (final e in headers.entries) {
      buf.writeln('    .addHeader("${e.key}", "${e.value}")');
    }
    buf.writeln('    .build();');
    buf.writeln('');
    buf.writeln('Response response = client.newCall(request).execute();');
    buf.writeln('System.out.println(response.code());');
    buf.writeln('System.out.println(response.body().string());');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // C# (HttpClient)
  // ─────────────────────────────────────────────────────────────────────────

  String _csharp(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln('using System.Net.Http;');
    buf.writeln('using System.Text;');
    buf.writeln('');
    buf.writeln('var handler = new HttpClientHandler()');
    buf.writeln('{');
    if (!settings.sslVerify) {
      buf.writeln('    ServerCertificateCustomValidationCallback = (_, _, _, _) => true,');
    }
    if (!settings.followRedirects) {
      buf.writeln('    AllowAutoRedirect = false,');
    }
    buf.writeln('};');
    buf.writeln('');
    buf.writeln('var client = new HttpClient(handler)');
    buf.writeln('{');
    buf.writeln('    Timeout = TimeSpan.FromMilliseconds(${settings.timeoutMs}),');
    buf.writeln('};');
    buf.writeln('');
    buf.writeln('var request = new HttpRequestMessage(HttpMethod.${_csharpMethod(method)}, "$fullUrl");');

    for (final e in headers.entries) {
      if (e.key == 'Content-Type') continue;
      buf.writeln('request.Headers.Add("${e.key}", "${e.value}");');
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('request.Content = new FormUrlEncodedContent(new Dictionary<string, string>');
      buf.writeln('{');
      for (final e in body.formData.entries) {
        buf.writeln('    { "${e.key}", "${e.value}" },');
      }
      buf.writeln('});');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      final ct = headers['Content-Type'] ?? 'application/json';
      buf.writeln('request.Content = new StringContent("$content", Encoding.UTF8, "$ct");');
    }
    buf.writeln('');
    buf.writeln('var response = await client.SendAsync(request);');
    buf.writeln('var responseBody = await response.Content.ReadAsStringAsync();');
    buf.writeln('Console.WriteLine(response.StatusCode);');
    buf.writeln('Console.WriteLine(responseBody);');

    return buf.toString();
  }

  String _csharpMethod(String method) => switch (method.toUpperCase()) {
        'GET' => 'Get',
        'POST' => 'Post',
        'PUT' => 'Put',
        'PATCH' => 'Patch',
        'DELETE' => 'Delete',
        'HEAD' => 'Head',
        'OPTIONS' => 'Options',
        _ => 'Get',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Go (net/http)
  // ─────────────────────────────────────────────────────────────────────────

  String _golang(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln('package main');
    buf.writeln('');
    buf.writeln('import (');
    buf.writeln('    "fmt"');
    buf.writeln('    "io"');
    buf.writeln('    "net/http"');
    if (_hasBody(body) || _isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('    "strings"');
    }
    if (settings.timeoutMs != 30000) {
      buf.writeln('    "time"');
    }
    if (!settings.sslVerify) {
      buf.writeln('    "crypto/tls"');
    }
    buf.writeln(')');
    buf.writeln('');
    buf.writeln('func main() {');

    // Body
    if (_isFormData(body) || _isUrlEncoded(body)) {
      final encoded = body.formData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      buf.writeln('    body := strings.NewReader("$encoded")');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      buf.writeln('    body := strings.NewReader("$content")');
    }

    final hasBodyVar = _hasBody(body) || _isFormData(body) || _isUrlEncoded(body);
    buf.writeln('    req, err := http.NewRequest("${method.toUpperCase()}", "$fullUrl", ${hasBodyVar ? 'body' : 'nil'})');
    buf.writeln('    if err != nil {');
    buf.writeln('        panic(err)');
    buf.writeln('    }');

    for (final e in headers.entries) {
      buf.writeln('    req.Header.Set("${e.key}", "${e.value}")');
    }
    buf.writeln('');

    if (!settings.sslVerify || settings.timeoutMs != 30000 || !settings.followRedirects) {
      buf.writeln('    client := &http.Client{');
      if (settings.timeoutMs != 30000) {
        buf.writeln('        Timeout: ${settings.timeoutMs} * time.Millisecond,');
      }
      if (!settings.sslVerify) {
        buf.writeln('        Transport: &http.Transport{');
        buf.writeln('            TLSClientConfig: &tls.Config{InsecureSkipVerify: true},');
        buf.writeln('        },');
      }
      if (!settings.followRedirects) {
        buf.writeln('        CheckRedirect: func(req *http.Request, via []*http.Request) error {');
        buf.writeln('            return http.ErrUseLastResponse');
        buf.writeln('        },');
      }
      buf.writeln('    }');
      buf.writeln('    resp, err := client.Do(req)');
    } else {
      buf.writeln('    resp, err := http.DefaultClient.Do(req)');
    }

    buf.writeln('    if err != nil {');
    buf.writeln('        panic(err)');
    buf.writeln('    }');
    buf.writeln('    defer resp.Body.Close()');
    buf.writeln('');
    buf.writeln('    respBody, _ := io.ReadAll(resp.Body)');
    buf.writeln('    fmt.Println(resp.StatusCode)');
    buf.writeln('    fmt.Println(string(respBody))');
    buf.writeln('}');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ruby (Net::HTTP)
  // ─────────────────────────────────────────────────────────────────────────

  String _ruby(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln("require 'net/http'");
    buf.writeln("require 'uri'");
    buf.writeln("require 'json'");
    buf.writeln('');
    buf.writeln('uri = URI.parse("$fullUrl")');
    buf.writeln('http = Net::HTTP.new(uri.host, uri.port)');
    buf.writeln('http.use_ssl = uri.scheme == "https"');
    if (!settings.sslVerify) {
      buf.writeln('http.verify_mode = OpenSSL::SSL::VERIFY_NONE');
    }
    if (settings.timeoutMs != 30000) {
      buf.writeln('http.read_timeout = ${(settings.timeoutMs / 1000).round()}');
    }
    buf.writeln('');
    buf.writeln('request = Net::HTTP::${_rubyMethod(method)}.new(uri.request_uri)');

    for (final e in headers.entries) {
      buf.writeln("request['${e.key}'] = '${e.value}'");
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('request.set_form_data({');
      for (final e in body.formData.entries) {
        buf.writeln("  '${e.key}' => '${e.value}',");
      }
      buf.writeln('})');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll("'", "\\'");
      buf.writeln("request.body = '$content'");
    }

    buf.writeln('');
    buf.writeln('response = http.request(request)');
    buf.writeln('puts response.code');
    buf.writeln('puts response.body');

    return buf.toString();
  }

  String _rubyMethod(String method) => switch (method.toUpperCase()) {
        'GET' => 'Get',
        'POST' => 'Post',
        'PUT' => 'Put',
        'PATCH' => 'Patch',
        'DELETE' => 'Delete',
        'HEAD' => 'Head',
        'OPTIONS' => 'Options',
        _ => 'Get',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // PHP (cURL)
  // ─────────────────────────────────────────────────────────────────────────

  String _php(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln('<?php');
    buf.writeln('');
    buf.writeln('\$ch = curl_init();');
    buf.writeln('');
    buf.writeln('curl_setopt(\$ch, CURLOPT_URL, "$fullUrl");');
    buf.writeln('curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);');
    buf.writeln('curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, "${method.toUpperCase()}");');

    if (headers.isNotEmpty) {
      buf.writeln('curl_setopt(\$ch, CURLOPT_HTTPHEADER, [');
      for (final e in headers.entries) {
        buf.writeln("    '${e.key}: ${e.value}',");
      }
      buf.writeln(']);');
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('curl_setopt(\$ch, CURLOPT_POSTFIELDS, http_build_query([');
      for (final e in body.formData.entries) {
        buf.writeln("    '${e.key}' => '${e.value}',");
      }
      buf.writeln(']));');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll("'", "\\'");
      buf.writeln("curl_setopt(\$ch, CURLOPT_POSTFIELDS, '$content');");
    }

    if (!settings.sslVerify) {
      buf.writeln('curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, false);');
    }
    if (settings.timeoutMs != 30000) {
      buf.writeln('curl_setopt(\$ch, CURLOPT_TIMEOUT, ${(settings.timeoutMs / 1000).round()});');
    }
    if (!settings.followRedirects) {
      buf.writeln('curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, false);');
    }

    buf.writeln('');
    buf.writeln('\$response = curl_exec(\$ch);');
    buf.writeln('\$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);');
    buf.writeln('curl_close(\$ch);');
    buf.writeln('');
    buf.writeln('echo \$httpCode . "\\n";');
    buf.writeln('echo \$response;');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Swift (URLSession)
  // ─────────────────────────────────────────────────────────────────────────

  String _swift(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final fullUrl = _buildUrl(url, params);
    final buf = StringBuffer();
    buf.writeln('import Foundation');
    buf.writeln('');
    buf.writeln('let url = URL(string: "$fullUrl")!');
    buf.writeln('var request = URLRequest(url: url)');
    buf.writeln('request.httpMethod = "${method.toUpperCase()}"');
    buf.writeln('request.timeoutInterval = ${(settings.timeoutMs / 1000).round()}');

    for (final e in headers.entries) {
      buf.writeln('request.setValue("${e.value}", forHTTPHeaderField: "${e.key}")');
    }

    if (_isFormData(body) || _isUrlEncoded(body)) {
      final encoded = body.formData.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      buf.writeln('request.httpBody = "$encoded".data(using: .utf8)');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      buf.writeln('request.httpBody = "$content".data(using: .utf8)');
    }

    buf.writeln('');
    buf.writeln('let task = URLSession.shared.dataTask(with: request) { data, response, error in');
    buf.writeln('    if let error = error {');
    buf.writeln('        print("Error: \\(error)")');
    buf.writeln('        return');
    buf.writeln('    }');
    buf.writeln('    if let httpResponse = response as? HTTPURLResponse {');
    buf.writeln('        print("Status: \\(httpResponse.statusCode)")');
    buf.writeln('    }');
    buf.writeln('    if let data = data, let body = String(data: data, encoding: .utf8) {');
    buf.writeln('        print(body)');
    buf.writeln('    }');
    buf.writeln('}');
    buf.writeln('task.resume()');

    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Kotlin (OkHttp)
  // ─────────────────────────────────────────────────────────────────────────

  String _kotlin(String method, String url, Map<String, String> headers,
      Map<String, String> params, CodegenBody body, CodegenSettings settings) {
    final buf = StringBuffer();
    buf.writeln('import okhttp3.*');
    buf.writeln('import java.util.concurrent.TimeUnit');
    buf.writeln('');
    buf.writeln('val client = OkHttpClient.Builder()');
    buf.writeln('    .connectTimeout(${settings.timeoutMs}L, TimeUnit.MILLISECONDS)');
    if (!settings.followRedirects) {
      buf.writeln('    .followRedirects(false)');
    }
    buf.writeln('    .build()');
    buf.writeln('');

    if (params.isNotEmpty) {
      buf.writeln('val urlBuilder = "$url".toHttpUrl().newBuilder()');
      for (final e in params.entries) {
        buf.writeln('    .addQueryParameter("${e.key}", "${e.value}")');
      }
      buf.writeln('val requestUrl = urlBuilder.build().toString()');
    } else {
      buf.writeln('val requestUrl = "$url"');
    }
    buf.writeln('');

    final ct = headers['Content-Type'] ?? 'application/json';
    final m = method.toUpperCase();
    if (_isFormData(body) || _isUrlEncoded(body)) {
      buf.writeln('val body = FormBody.Builder()');
      for (final e in body.formData.entries) {
        buf.writeln('    .add("${e.key}", "${e.value}")');
      }
      buf.writeln('    .build()');
    } else if (_hasBody(body)) {
      final content = _bodyContent(body).replaceAll('"', '\\"');
      buf.writeln('val mediaType = "$ct".toMediaType()');
      buf.writeln('val body = "$content".toRequestBody(mediaType)');
    }
    buf.writeln('');

    buf.writeln('val request = Request.Builder()');
    buf.writeln('    .url(requestUrl)');

    final hasBodyVar = _hasBody(body) || _isFormData(body) || _isUrlEncoded(body);
    if (hasBodyVar) {
      buf.writeln('    .method("$m", body)');
    } else if (m == 'GET' || m == 'HEAD') {
      buf.writeln('    .method("$m", null)');
    } else {
      buf.writeln('    .method("$m", "".toRequestBody(null))');
    }

    for (final e in headers.entries) {
      buf.writeln('    .addHeader("${e.key}", "${e.value}")');
    }
    buf.writeln('    .build()');
    buf.writeln('');
    buf.writeln('val response = client.newCall(request).execute()');
    buf.writeln('println(response.code)');
    buf.writeln('println(response.body?.string())');

    return buf.toString();
  }
}
