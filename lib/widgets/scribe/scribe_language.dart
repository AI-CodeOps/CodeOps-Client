/// Language detection and mapping for [ScribeEditor].
///
/// Maps file extensions and language identifiers to syntax highlighting
/// modes. Supports 31 programming languages with file extension detection
/// and human-readable display names.
library;

/// Utility for mapping file extensions and language identifiers to
/// syntax highlighting modes.
///
/// Provides a centralized mapping used by [ScribeEditor] to determine
/// the correct syntax highlighting grammar for a given file or language.
///
/// Example:
/// ```dart
/// final lang = ScribeLanguage.fromFileName('main.dart');
/// // lang == 'dart'
/// ```
class ScribeLanguage {
  ScribeLanguage._();

  /// Maps file extensions (including the dot) to language identifiers.
  static const Map<String, String> _extensionMap = {
    '.bash': 'bash',
    '.c': 'c',
    '.cc': 'cpp',
    '.cjs': 'javascript',
    '.conf': 'ini',
    '.cpp': 'cpp',
    '.cs': 'csharp',
    '.css': 'css',
    '.cts': 'typescript',
    '.cxx': 'cpp',
    '.dart': 'dart',
    '.dockerfile': 'dockerfile',
    '.go': 'go',
    '.gql': 'graphql',
    '.graphql': 'graphql',
    '.groovy': 'groovy',
    '.gvy': 'groovy',
    '.h': 'c',
    '.hh': 'cpp',
    '.hpp': 'cpp',
    '.htm': 'html',
    '.html': 'html',
    '.hxx': 'cpp',
    '.ini': 'ini',
    '.java': 'java',
    '.js': 'javascript',
    '.json': 'json',
    '.kt': 'kotlin',
    '.kts': 'kotlin',
    '.lua': 'lua',
    '.m': 'objectivec',
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.mjs': 'javascript',
    '.mts': 'typescript',
    '.perl': 'perl',
    '.php': 'php',
    '.pl': 'perl',
    '.pm': 'perl',
    '.properties': 'properties',
    '.py': 'python',
    '.pyw': 'python',
    '.rb': 'ruby',
    '.rs': 'rust',
    '.scala': 'scala',
    '.sh': 'bash',
    '.shell': 'shell',
    '.sql': 'sql',
    '.swift': 'swift',
    '.toml': 'toml',
    '.ts': 'typescript',
    '.tsx': 'typescript',
    '.txt': 'plaintext',
    '.xml': 'xml',
    '.xsd': 'xml',
    '.xsl': 'xml',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.zsh': 'bash',
  };

  /// Maps exact file names (case-insensitive) to language identifiers.
  static const Map<String, String> _fileNameMap = {
    'dockerfile': 'dockerfile',
    'makefile': 'makefile',
    'gemfile': 'ruby',
    'rakefile': 'ruby',
    'cmakelists.txt': 'cmake',
    '.gitignore': 'plaintext',
    '.env': 'ini',
  };

  /// Human-readable display names for each language identifier.
  static const Map<String, String> _displayNames = {
    'bash': 'Bash',
    'c': 'C',
    'cmake': 'CMake',
    'cpp': 'C++',
    'csharp': 'C#',
    'css': 'CSS',
    'dart': 'Dart',
    'dockerfile': 'Dockerfile',
    'go': 'Go',
    'graphql': 'GraphQL',
    'groovy': 'Groovy',
    'html': 'HTML',
    'ini': 'INI',
    'java': 'Java',
    'javascript': 'JavaScript',
    'json': 'JSON',
    'kotlin': 'Kotlin',
    'lua': 'Lua',
    'makefile': 'Makefile',
    'markdown': 'Markdown',
    'objectivec': 'Objective-C',
    'perl': 'Perl',
    'php': 'PHP',
    'plaintext': 'Plain Text',
    'properties': 'Properties',
    'python': 'Python',
    'ruby': 'Ruby',
    'rust': 'Rust',
    'scala': 'Scala',
    'shell': 'Shell',
    'sql': 'SQL',
    'swift': 'Swift',
    'toml': 'TOML',
    'typescript': 'TypeScript',
    'xml': 'XML',
    'yaml': 'YAML',
  };

  /// File extensions associated with each language identifier.
  static const Map<String, List<String>> _languageExtensions = {
    'bash': ['.sh', '.bash', '.zsh'],
    'c': ['.c', '.h'],
    'cmake': [],
    'cpp': ['.cpp', '.cc', '.cxx', '.hpp', '.hh', '.hxx'],
    'csharp': ['.cs'],
    'css': ['.css'],
    'dart': ['.dart'],
    'dockerfile': ['.dockerfile'],
    'go': ['.go'],
    'graphql': ['.graphql', '.gql'],
    'groovy': ['.groovy', '.gvy'],
    'html': ['.html', '.htm'],
    'ini': ['.ini', '.conf'],
    'java': ['.java'],
    'javascript': ['.js', '.mjs', '.cjs'],
    'json': ['.json'],
    'kotlin': ['.kt', '.kts'],
    'lua': ['.lua'],
    'makefile': [],
    'markdown': ['.md', '.markdown'],
    'objectivec': ['.m'],
    'perl': ['.pl', '.pm', '.perl'],
    'php': ['.php'],
    'plaintext': ['.txt'],
    'properties': ['.properties'],
    'python': ['.py', '.pyw'],
    'ruby': ['.rb'],
    'rust': ['.rs'],
    'scala': ['.scala'],
    'shell': ['.shell'],
    'sql': ['.sql'],
    'swift': ['.swift'],
    'toml': ['.toml'],
    'typescript': ['.ts', '.tsx', '.mts', '.cts'],
    'xml': ['.xml', '.xsl', '.xsd'],
    'yaml': ['.yaml', '.yml'],
  };

  /// Maps language identifiers to their re_highlight mode keys.
  ///
  /// Most languages use the same key. Some map to a different mode:
  /// - `html` uses `xml` mode
  /// - `toml` uses `ini` mode
  /// - `shell` uses `bash` mode
  /// - `makefile` uses `makefile` mode
  static const Map<String, String> highlightModeKeys = {
    'bash': 'bash',
    'c': 'c',
    'cmake': 'cmake',
    'cpp': 'cpp',
    'csharp': 'csharp',
    'css': 'css',
    'dart': 'dart',
    'dockerfile': 'dockerfile',
    'go': 'go',
    'graphql': 'graphql',
    'groovy': 'groovy',
    'html': 'xml',
    'ini': 'ini',
    'java': 'java',
    'javascript': 'javascript',
    'json': 'json',
    'kotlin': 'kotlin',
    'lua': 'lua',
    'makefile': 'makefile',
    'markdown': 'markdown',
    'objectivec': 'objectivec',
    'perl': 'perl',
    'php': 'php',
    'plaintext': 'plaintext',
    'properties': 'properties',
    'python': 'python',
    'ruby': 'ruby',
    'rust': 'rust',
    'scala': 'scala',
    'shell': 'shell',
    'sql': 'sql',
    'swift': 'swift',
    'toml': 'ini',
    'typescript': 'typescript',
    'xml': 'xml',
    'yaml': 'yaml',
  };

  /// Maps a file name or path to a language identifier.
  ///
  /// Returns `'plaintext'` if the extension is not recognized.
  ///
  /// Handles:
  /// - Paths with directories (extracts the basename)
  /// - Files with no extension (e.g., `Dockerfile`, `Makefile`)
  /// - Case-insensitive extension matching
  ///
  /// Example:
  /// ```dart
  /// ScribeLanguage.fromFileName('main.dart');       // 'dart'
  /// ScribeLanguage.fromFileName('Dockerfile');       // 'dockerfile'
  /// ScribeLanguage.fromFileName('src/App.java');     // 'java'
  /// ScribeLanguage.fromFileName('unknown.xyz');      // 'plaintext'
  /// ```
  static String fromFileName(String fileName) {
    // Extract basename from path.
    final lastSlash = fileName.lastIndexOf('/');
    final basename =
        lastSlash >= 0 ? fileName.substring(lastSlash + 1) : fileName;
    final lowerBasename = basename.toLowerCase();

    // Check exact file name matches first.
    final nameMatch = _fileNameMap[lowerBasename];
    if (nameMatch != null) {
      return nameMatch;
    }

    // Extract extension.
    final dotIndex = basename.lastIndexOf('.');
    if (dotIndex < 0) {
      return 'plaintext';
    }

    final extension = basename.substring(dotIndex).toLowerCase();
    return _extensionMap[extension] ?? 'plaintext';
  }

  /// All supported language identifiers, sorted alphabetically.
  static List<String> get supportedLanguages {
    final languages = _displayNames.keys.toList()..sort();
    return languages;
  }

  /// Human-readable display name for a language identifier.
  ///
  /// Returns the identifier itself (capitalized) if no display name is
  /// registered.
  ///
  /// Example:
  /// ```dart
  /// ScribeLanguage.displayName('javascript'); // 'JavaScript'
  /// ScribeLanguage.displayName('sql');         // 'SQL'
  /// ```
  static String displayName(String language) {
    return _displayNames[language] ?? language;
  }

  /// File extension(s) associated with a language identifier.
  ///
  /// Returns an empty list if the language has no registered extensions
  /// (e.g., `makefile` which is detected by filename).
  ///
  /// Example:
  /// ```dart
  /// ScribeLanguage.extensions('dart');       // ['.dart']
  /// ScribeLanguage.extensions('javascript'); // ['.js', '.mjs', '.cjs']
  /// ```
  static List<String> extensions(String language) {
    return _languageExtensions[language] ?? <String>[];
  }
}
