// Unit tests for CodeGenerationService.
import 'package:flutter_test/flutter_test.dart';

import 'package:codeops/models/courier_enums.dart';
import 'package:codeops/services/courier/code_generation_service.dart';

void main() {
  const svc = CodeGenerationService();

  // ─────────────────────────────────────────────────────────────────────────
  // cURL
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — cURL', () {
    test('generates GET request', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('curl -X GET'));
      expect(code, contains('https://api.example.com/users'));
    });

    test('generates POST with JSON body', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'POST',
        url: 'https://api.example.com/users',
        body: const CodegenBody(
          type: BodyType.rawJson,
          rawContent: '{"name":"John"}',
        ),
      );
      expect(code, contains('curl -X POST'));
      expect(code, contains("-d '"));
      expect(code, contains('Content-Type: application/json'));
    });

    test('includes custom headers', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'GET',
        url: 'https://api.example.com',
        headers: {'X-Custom': 'value'},
      );
      expect(code, contains("-H 'X-Custom: value'"));
    });

    test('includes auth header for bearer token', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'GET',
        url: 'https://api.example.com',
        auth: const CodegenAuth(
          type: AuthType.bearerToken,
          bearerToken: 'tok123',
        ),
      );
      expect(code, contains('Authorization: Bearer tok123'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Python
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Python', () {
    test('generates GET request', () {
      final code = svc.generate(
        language: CodeLanguage.pythonRequests,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('import requests'));
      expect(code, contains('requests.get(url'));
    });

    test('generates POST with JSON body', () {
      final code = svc.generate(
        language: CodeLanguage.pythonRequests,
        method: 'POST',
        url: 'https://api.example.com/users',
        body: const CodegenBody(
          type: BodyType.rawJson,
          rawContent: '{"name":"John"}',
        ),
      );
      expect(code, contains('requests.post(url'));
      expect(code, contains('json=json_data'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // JavaScript (Fetch)
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — JavaScript Fetch', () {
    test('generates fetch call', () {
      final code = svc.generate(
        language: CodeLanguage.javascriptFetch,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('fetch('));
      expect(code, contains('method: "GET"'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // JavaScript (Axios)
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — JavaScript Axios', () {
    test('generates axios call', () {
      final code = svc.generate(
        language: CodeLanguage.javascriptAxios,
        method: 'POST',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('axios'));
      expect(code, contains('method: "post"'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Java (HttpClient)
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Java HttpClient', () {
    test('generates HttpClient code', () {
      final code = svc.generate(
        language: CodeLanguage.javaHttpClient,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('HttpClient'));
      expect(code, contains('HttpRequest'));
      expect(code, contains('.method("GET"'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Java (OkHttp)
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Java OkHttp', () {
    test('generates OkHttp code', () {
      final code = svc.generate(
        language: CodeLanguage.javaOkhttp,
        method: 'PUT',
        url: 'https://api.example.com/users/1',
      );
      expect(code, contains('OkHttpClient'));
      expect(code, contains('Request.Builder()'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // C# (HttpClient)
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — C#', () {
    test('generates HttpClient code', () {
      final code = svc.generate(
        language: CodeLanguage.csharpHttpClient,
        method: 'DELETE',
        url: 'https://api.example.com/users/1',
      );
      expect(code, contains('HttpClient'));
      expect(code, contains('HttpMethod.Delete'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Go
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Go', () {
    test('generates net/http code', () {
      final code = svc.generate(
        language: CodeLanguage.go,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('package main'));
      expect(code, contains('http.NewRequest'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Ruby
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Ruby', () {
    test('generates Net::HTTP code', () {
      final code = svc.generate(
        language: CodeLanguage.ruby,
        method: 'PATCH',
        url: 'https://api.example.com/users/1',
      );
      expect(code, contains("require 'net/http'"));
      expect(code, contains('Net::HTTP::Patch'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PHP
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — PHP', () {
    test('generates PHP cURL code', () {
      final code = svc.generate(
        language: CodeLanguage.php,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('<?php'));
      expect(code, contains('curl_init'));
      expect(code, contains('CURLOPT_CUSTOMREQUEST'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Swift
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Swift', () {
    test('generates URLSession code', () {
      final code = svc.generate(
        language: CodeLanguage.swift,
        method: 'POST',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('import Foundation'));
      expect(code, contains('URLRequest'));
      expect(code, contains('URLSession.shared'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Kotlin
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — Kotlin', () {
    test('generates OkHttp code', () {
      final code = svc.generate(
        language: CodeLanguage.kotlin,
        method: 'GET',
        url: 'https://api.example.com/users',
      );
      expect(code, contains('import okhttp3'));
      expect(code, contains('OkHttpClient'));
      expect(code, contains('Request.Builder()'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Cross-cutting concerns
  // ─────────────────────────────────────────────────────────────────────────

  group('CodeGenerationService — cross-cutting', () {
    test('includes query params in URL', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'GET',
        url: 'https://api.example.com/users',
        queryParams: {'page': '1', 'limit': '10'},
      );
      expect(code, contains('page=1'));
      expect(code, contains('limit=10'));
    });

    test('generates JSON body for all languages', () {
      for (final lang in CodeLanguage.values) {
        final code = svc.generate(
          language: lang,
          method: 'POST',
          url: 'https://api.example.com/data',
          body: const CodegenBody(
            type: BodyType.rawJson,
            rawContent: '{"key":"value"}',
          ),
        );
        // All languages should have some code generated.
        expect(code.isNotEmpty, true, reason: '${lang.name} should produce code');
      }
    });

    test('handles form data body', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'POST',
        url: 'https://api.example.com/form',
        body: const CodegenBody(
          type: BodyType.formData,
          formData: {'field1': 'value1', 'field2': 'value2'},
        ),
      );
      expect(code, contains("-F 'field1=value1'"));
      expect(code, contains("-F 'field2=value2'"));
    });

    test('includes bearer auth header', () {
      final code = svc.generate(
        language: CodeLanguage.pythonRequests,
        method: 'GET',
        url: 'https://api.example.com',
        auth: const CodegenAuth(
          type: AuthType.bearerToken,
          bearerToken: 'mytoken',
        ),
      );
      expect(code, contains('Authorization'));
      expect(code, contains('Bearer mytoken'));
    });

    test('includes basic auth header', () {
      final code = svc.generate(
        language: CodeLanguage.curl,
        method: 'GET',
        url: 'https://api.example.com',
        auth: const CodegenAuth(
          type: AuthType.basicAuth,
          basicUsername: 'user',
          basicPassword: 'pass',
        ),
      );
      expect(code, contains('Authorization'));
      expect(code, contains('Basic'));
    });

    test('returns correct file extensions', () {
      expect(svc.fileExtension(CodeLanguage.curl), 'sh');
      expect(svc.fileExtension(CodeLanguage.pythonRequests), 'py');
      expect(svc.fileExtension(CodeLanguage.javascriptFetch), 'js');
      expect(svc.fileExtension(CodeLanguage.javaHttpClient), 'java');
      expect(svc.fileExtension(CodeLanguage.csharpHttpClient), 'cs');
      expect(svc.fileExtension(CodeLanguage.go), 'go');
      expect(svc.fileExtension(CodeLanguage.ruby), 'rb');
      expect(svc.fileExtension(CodeLanguage.php), 'php');
      expect(svc.fileExtension(CodeLanguage.swift), 'swift');
      expect(svc.fileExtension(CodeLanguage.kotlin), 'kt');
    });
  });
}
