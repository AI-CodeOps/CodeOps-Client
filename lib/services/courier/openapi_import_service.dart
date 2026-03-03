/// Client-side service for converting OpenAPI specs into Courier collection
/// import structures.
///
/// Parses an [OpenApiSpec] (produced by [OpenApiParser]) and generates a
/// [CollectionImportData] with folders grouped by tag and requests with
/// method, path, headers, parameters, and example request bodies.
library;

import 'dart:convert';

import '../../models/courier_enums.dart';
import '../../models/openapi_spec.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Import data models
// ─────────────────────────────────────────────────────────────────────────────

/// Import data for a single request to create in a collection.
class RequestImportData {
  /// Display name (summary or operationId or `METHOD /path`).
  final String name;

  /// HTTP method (GET, POST, etc.).
  final CourierHttpMethod method;

  /// URL path template (e.g., `/api/v1/users/{userId}`).
  final String path;

  /// Optional description.
  final String? description;

  /// Headers to set on the request.
  final Map<String, String> headers;

  /// Query parameters.
  final Map<String, String> queryParams;

  /// Path parameters.
  final Map<String, String> pathParams;

  /// Example request body (JSON string), if applicable.
  final String? requestBody;

  /// Tag / folder name for grouping.
  final String? folder;

  /// Creates a [RequestImportData].
  const RequestImportData({
    required this.name,
    required this.method,
    required this.path,
    this.description,
    this.headers = const {},
    this.queryParams = const {},
    this.pathParams = const {},
    this.requestBody,
    this.folder,
  });
}

/// Import data for a folder within a collection.
class FolderImportData {
  /// Folder name (from tag).
  final String name;

  /// Optional description (from tag description).
  final String? description;

  /// Requests belonging to this folder.
  final List<RequestImportData> requests;

  /// Creates a [FolderImportData].
  const FolderImportData({
    required this.name,
    this.description,
    this.requests = const [],
  });
}

/// Complete import data for creating a Courier collection from an OpenAPI spec.
class CollectionImportData {
  /// Collection name (from `info.title`).
  final String collectionName;

  /// Folders grouped by tag.
  final List<FolderImportData> folders;

  /// Un-tagged requests (no folder).
  final List<RequestImportData> ungroupedRequests;

  /// Total request count.
  int get totalRequests =>
      folders.fold<int>(0, (sum, f) => sum + f.requests.length) +
      ungroupedRequests.length;

  /// Creates a [CollectionImportData].
  const CollectionImportData({
    required this.collectionName,
    this.folders = const [],
    this.ungroupedRequests = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Converts an [OpenApiSpec] into a [CollectionImportData] ready for
/// programmatic collection creation via the Courier API.
class OpenApiImportService {
  /// Creates an [OpenApiImportService].
  const OpenApiImportService();

  /// Parses an [OpenApiSpec] and produces [CollectionImportData].
  ///
  /// Endpoints are grouped by their first tag into folders. Endpoints
  /// without tags are placed in [CollectionImportData.ungroupedRequests].
  /// Query and path parameters are extracted. Example request bodies are
  /// generated from schema definitions when available.
  CollectionImportData importSpec(OpenApiSpec spec) {
    final folderMap = <String, List<RequestImportData>>{};
    final ungrouped = <RequestImportData>[];

    // Build tag description lookup.
    final tagDescriptions = <String, String?>{};
    for (final tag in spec.tags) {
      tagDescriptions[tag.name] = tag.description;
    }

    for (final endpoint in spec.endpoints) {
      final request = _endpointToRequest(endpoint, spec);

      if (endpoint.tags.isNotEmpty) {
        final tag = endpoint.tags.first;
        folderMap.putIfAbsent(tag, () => []).add(request);
      } else {
        ungrouped.add(request);
      }
    }

    // Build folder list preserving tag order from spec.
    final folders = <FolderImportData>[];
    final addedTags = <String>{};

    // Add folders in spec tag order first.
    for (final tag in spec.tags) {
      if (folderMap.containsKey(tag.name)) {
        folders.add(FolderImportData(
          name: tag.name,
          description: tag.description,
          requests: folderMap[tag.name]!,
        ));
        addedTags.add(tag.name);
      }
    }

    // Add any remaining tags not in spec.tags.
    for (final entry in folderMap.entries) {
      if (!addedTags.contains(entry.key)) {
        folders.add(FolderImportData(
          name: entry.key,
          requests: entry.value,
        ));
      }
    }

    return CollectionImportData(
      collectionName: spec.title,
      folders: folders,
      ungroupedRequests: ungrouped,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  RequestImportData _endpointToRequest(
      OpenApiEndpoint endpoint, OpenApiSpec spec) {
    final method = _parseMethod(endpoint.method);
    final name = endpoint.summary ??
        endpoint.operationId ??
        '${endpoint.method.toUpperCase()} ${endpoint.path}';

    // Extract parameters by location.
    final queryParams = <String, String>{};
    final pathParams = <String, String>{};
    final headers = <String, String>{};

    for (final param in endpoint.parameters) {
      final exampleValue =
          param.schema?.example?.toString() ?? '{${param.name}}';
      switch (param.location) {
        case 'query':
          queryParams[param.name] = exampleValue;
        case 'path':
          pathParams[param.name] = exampleValue;
        case 'header':
          if (param.name != 'Authorization' &&
              param.name != 'Content-Type') {
            headers[param.name] = exampleValue;
          }
      }
    }

    // Extract request body example.
    String? bodyJson;
    if (endpoint.requestBody != null) {
      final jsonContent =
          endpoint.requestBody!.content['application/json'];
      if (jsonContent != null) {
        bodyJson = _generateExampleBody(jsonContent.schema, spec.schemas);
        if (bodyJson != null) {
          headers['Content-Type'] = 'application/json';
        }
      }
    }

    return RequestImportData(
      name: name,
      method: method,
      path: endpoint.path,
      description: endpoint.description,
      headers: headers,
      queryParams: queryParams,
      pathParams: pathParams,
      requestBody: bodyJson,
      folder: endpoint.tags.isNotEmpty ? endpoint.tags.first : null,
    );
  }

  CourierHttpMethod _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return CourierHttpMethod.get;
      case 'POST':
        return CourierHttpMethod.post;
      case 'PUT':
        return CourierHttpMethod.put;
      case 'PATCH':
        return CourierHttpMethod.patch;
      case 'DELETE':
        return CourierHttpMethod.delete;
      case 'HEAD':
        return CourierHttpMethod.head;
      case 'OPTIONS':
        return CourierHttpMethod.options;
      default:
        return CourierHttpMethod.get;
    }
  }

  /// Generates a JSON example body from a schema definition.
  ///
  /// Resolves `$ref` references, handles object/array/primitive types,
  /// and uses `example` values when available.
  String? _generateExampleBody(
      OpenApiSchema schema, Map<String, OpenApiSchema> schemas) {
    final value = _schemaToExample(schema, schemas, 0);
    if (value == null) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  dynamic _schemaToExample(
      OpenApiSchema schema, Map<String, OpenApiSchema> schemas, int depth) {
    // Prevent infinite recursion.
    if (depth > 5) return null;

    // Resolve $ref.
    if (schema.ref != null) {
      final resolved = schemas[schema.ref!];
      if (resolved != null) {
        return _schemaToExample(resolved, schemas, depth + 1);
      }
      return null;
    }

    // Use explicit example.
    if (schema.example != null) return schema.example;

    switch (schema.type) {
      case 'object':
        if (schema.properties == null || schema.properties!.isEmpty) {
          return <String, dynamic>{};
        }
        final obj = <String, dynamic>{};
        for (final entry in schema.properties!.entries) {
          obj[entry.key] =
              _schemaToExample(entry.value, schemas, depth + 1) ??
                  _defaultForType(entry.value);
        }
        return obj;

      case 'array':
        if (schema.items != null) {
          final item =
              _schemaToExample(schema.items!, schemas, depth + 1);
          return [if (item != null) item];
        }
        return [];

      case 'string':
        if (schema.enumValues != null && schema.enumValues!.isNotEmpty) {
          return schema.enumValues!.first;
        }
        if (schema.format == 'uuid') return '00000000-0000-0000-0000-000000000000';
        if (schema.format == 'date-time') return '2026-01-01T00:00:00Z';
        if (schema.format == 'date') return '2026-01-01';
        return 'string';

      case 'integer':
      case 'number':
        return 0;

      case 'boolean':
        return false;

      default:
        return null;
    }
  }

  dynamic _defaultForType(OpenApiSchema schema) {
    if (schema.ref != null) return {};
    switch (schema.type) {
      case 'string':
        return 'string';
      case 'integer':
      case 'number':
        return 0;
      case 'boolean':
        return false;
      case 'array':
        return [];
      case 'object':
        return {};
      default:
        return null;
    }
  }
}
