library shelf_static.staic_handler;

import 'dart:async';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import 'util.dart';

// TODO option to exclude hidden files?

/// Creates a Shelf [Handler] that serves files from the provided
/// [fileSystemPath].
///
/// Accessing a path containing symbolic links will succeed only if the resolved
/// path is within [fileSystemPath]. To allow access to paths outside of
/// [fileSystemPath], set [serveFilesOutsidePath] to `true`.
///
/// When a existing directory is requested and a [defaultDocument] is specified
/// the directory is checked for a file with that name. If it exists, it is
/// served.
Handler createStaticHandler(String fileSystemPath,
    {bool serveFilesOutsidePath: false, String defaultDocument}) {
  var rootDir = new Directory(fileSystemPath);
  if (!rootDir.existsSync()) {
    throw new ArgumentError('A directory corresponding to fileSystemPath '
        '"$fileSystemPath" could not be found');
  }

  fileSystemPath = rootDir.resolveSymbolicLinksSync();

  if (defaultDocument != null) {
    if (defaultDocument != p.basename(defaultDocument)) {
      throw new ArgumentError('defaultDocument must be a file name.');
    }
  }

  return (Request request) {
  return new Future.microtask(() {
    var segs = [
        fileSystemPath
    ]
        ..addAll(request.url.pathSegments);
    var fsPath = p.joinAll(segs);
    return FileSystemEntity.type(fsPath, followLinks: true).then((x0) {
      var entityType = x0;
      var file = null;
      join0() {
        join1() {
          join2() {
            join3() {
              return file.stat().then((x1) {
                var fileStat = x1;
                var ifModifiedSince = request.ifModifiedSince;
                join4() {
                  var headers = {
                      HttpHeaders.CONTENT_LENGTH: fileStat.size.toString(),
                      HttpHeaders.LAST_MODIFIED: formatHttpDate(fileStat.changed)
                  };
                  var contentType = mime.lookupMimeType(file.path);
                  join5() {
                    return new Response.ok(file.openRead(), headers: headers);
                  }
                  if (contentType != null) {
                    headers[HttpHeaders.CONTENT_TYPE] = contentType;
                    return join5();
                  } else {
                    return join5();
                  }
                }
                if (ifModifiedSince != null) {
                  var fileChangeAtSecResolution = toSecondResolution(fileStat.changed);
                  if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
                    return new Response.notModified();
                  } else {
                    return join4();
                  }
                } else {
                  return join4();
                }
              });
            }
            if (entityType == FileSystemEntityType.DIRECTORY && !request.url.path.endsWith('/')) {
              var uri = request.requestedUri;
              assert(!uri.path.endsWith('/'));
              var location = new Uri(scheme: uri.scheme, userInfo: uri.userInfo, host: uri.host, port: uri.port, path: uri.path + '/', query: uri.query);
              return new Response.movedPermanently(location.toString());
            } else {
              return join3();
            }
          }
          if (!serveFilesOutsidePath) {
            return file.resolveSymbolicLinks().then((x2) {
              var resolvedPath = x2;
              join7() {
                return join2();
              }
              if (!p.isWithin(fileSystemPath, resolvedPath)) {
                return new Response.notFound('Not Found');
              } else {
                return join7();
              }
            });
          } else {
            return join2();
          }
        }
        if (file == null) {
          return new Response.notFound('Not Found');
        } else {
          return join1();
        }
      }
      if (entityType == FileSystemEntityType.FILE) {
        file = new File(fsPath);
        return join0();
      } else {
        if (entityType == FileSystemEntityType.DIRECTORY) {
          return _tryDefaultFile(fsPath, defaultDocument).then((x3) {
            file = x3;
            return join0();
          });
        } else {
          return join0();
        }
      }
    });
  });
};
}

Future<File> _tryDefaultFile(String dirPath, String defaultFile) {
  return new Future.microtask(() {
    join0() {
      var filePath = p.join(dirPath, defaultFile);
      var file = new File(filePath);
      return file.exists().then((x0) {
        if (x0) {
          return file;
        } else {
          return null;
        }
      });
    }
    if (defaultFile == null) {
      return null;
    } else {
      return join0();
    }
  });
}

