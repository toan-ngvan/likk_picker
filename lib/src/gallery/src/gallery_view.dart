import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import 'package:likk_picker/likk_picker.dart';
import 'package:likk_picker/src/animations/animations.dart';
import 'package:likk_picker/src/camera/camera_view.dart';
import 'package:likk_picker/src/playground/playground.dart';
import 'package:likk_picker/src/slidable_panel/slidable_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

// ignore: always_use_package_imports
import '../../likk_entity.dart';
// ignore: always_use_package_imports
import 'controllers/gallery_repository.dart';
// ignore: always_use_package_imports
import 'entities/gallery_setting.dart';
// ignore: always_use_package_imports
import 'entities/gallery_value.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_album_view.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_asset_selector.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_controller_provider.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_grid_view.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_header.dart';
// ignore: always_use_package_imports
import 'widgets/gallery_recent_preview.dart';

///
///
///
///
///
class GalleryViewWrapper extends StatefulWidget {
  ///
  const GalleryViewWrapper({
    Key? key,
    required this.child,
    required this.controller,
    this.safeAreaBottom = false,
  }) : super(key: key);

  ///
  final Widget child;

  ///
  final bool safeAreaBottom;

  ///
  final GalleryController controller;

  @override
  _GalleryViewWrapperState createState() => _GalleryViewWrapperState();
}

class _GalleryViewWrapperState extends State<GalleryViewWrapper> {
  late GalleryController _controller;
  late final PanelController panelController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    panelController = _controller.panelController;
  }

  @override
  Widget build(BuildContext context) {
    final ps = _controller.panelSetting;
    final hs = _controller.headerSetting;
    final _panelMaxHeight =
        ps.maxHeight ?? MediaQuery.of(context).size.height - hs.topMargin;

    if (MediaQuery.of(context).viewInsets.bottom != 0 &&
        MediaQuery.of(context).viewInsets.bottom > (_panelMaxHeight * 0.37)) {
      kKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    }

    final _panelMinHeight =
        (ps.minHeight ?? kKeyboardHeight ?? _panelMaxHeight * 0.37) -
            (widget.safeAreaBottom ? MediaQuery.of(context).padding.bottom : 0);

    final showKeyboard = MediaQuery.of(context).viewInsets.bottom != 0.0;

    return Material(
      key: _controller._wrapperKey,
      child: GalleryControllerProvider(
        controller: _controller,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Parent view
            Column(
              children: [
                //
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      final focusManager = FocusManager.instance.primaryFocus;
                      if (focusManager!.hasFocus) {
                        focusManager.unfocus();
                      }
                      if (panelController.isVisible) {
                        _controller._closePanel();
                      }
                    },
                    child: Builder(builder: (_) => widget.child),
                  ),
                ),

                // Space for panel min height
                ValueListenableBuilder<bool>(
                  valueListenable: panelController.panelVisibility,
                  builder: (context, isVisible, child) {
                    return SizedBox(
                      height: !showKeyboard && isVisible ? _panelMinHeight : 0,
                    );
                  },
                ),

                //
              ],
            ),

            // Gallery
            SlidablePanel(
              galleryController: _controller,
              controller: panelController,
              child: Builder(
                builder: (_) => GalleryView(controller: _controller),
              ),
            ),

            //
          ],
        ),
      ),
    );

    //
  }
}

///
///
///
///
class GalleryView extends StatefulWidget {
  ///
  const GalleryView({
    Key? key,
    this.controller,
  }) : super(key: key);

  ///
  final GalleryController? controller;

  ///
  static const String name = 'GalleryView';

  ///
  static Future<List<LikkEntity>?> pick(BuildContext context) {
    return Navigator.of(context).push<List<LikkEntity>>(
      SlideTransitionPageRoute(
        builder: const GalleryView(),
        transitionCurve: Curves.easeIn,
        settings: const RouteSettings(name: name),
      ),
    );
  }

  @override
  _GalleryViewState createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView>
    with SingleTickerProviderStateMixin {
  late final GalleryController _controller;
  late final PanelController panelController;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  double albumHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GalleryController();

    panelController = _controller.panelController;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 300),
      value: 0,
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  void _toogleAlbumList(bool isVisible) {
    if (_animationController.isAnimating) return;
    _controller._setAlbumVisibility(!isVisible);
    panelController.isGestureEnabled = _animationController.value == 1.0;
    if (_animationController.value == 1.0) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  //
  // void _showAlert(GallerySetting gallerySetting) {
  //   final cancel = TextButton(
  //     onPressed: Navigator.of(context).pop,
  //     child: Text(
  //       'CANCEL',
  //       style: Theme.of(context).textTheme.button!.copyWith(
  //             color: Colors.lightBlue,
  //           ),
  //     ),
  //   );
  //   final unselectItems = TextButton(
  //     onPressed: _onSelectionClear,
  //     child: Text(
  //       'USELECT ITEMS',
  //       style: Theme.of(context).textTheme.button!.copyWith(
  //             color: Colors.blue,
  //           ),
  //     ),
  //   );

  //   final alertDialog = AlertDialog(
  //     title: Text(
  //       'Unselect these items?',
  //       style: Theme.of(context).textTheme.headline6!.copyWith(
  //             color: Colors.white70,
  //           ),
  //     ),
  //     content: Text(
  //       'Going back will undo the selections you made.',
  //       style: Theme.of(context).textTheme.bodyText2!.copyWith(
  //             color: Colors.grey.shade600,
  //           ),
  //     ),
  //     actions: [cancel, unselectItems],
  //     backgroundColor: Colors.grey.shade900,
  //     titlePadding: const EdgeInsets.all(16),
  //     contentPadding: const EdgeInsets.symmetric(
  //       horizontal: 16,
  //       vertical: 2,
  //     ),
  //   );

  //   showDialog<void>(
  //     context: context,
  //     builder: (context) => alertDialog,
  //   );
  // }

  Future<bool> _onClosePressed() async {
    if (_animationController.isAnimating) return false;

    if (_controller._albumVisibility.value) {
      _toogleAlbumList(true);
      return false;
    }

    if (_controller.fullScreenMode) {
      // if (_controller.value.selectedEntities.isNotEmpty &&
      //     _controller.setting.onUnselectAll == null) {
      //   _showAlert(_controller.setting);
      //   return false;
      // }
      if (_controller.setting.backAndUnselect == null ||
          _controller.setting.backAndUnselect!()) {
        _controller._internal = true;
        // ignore: cascade_invocations
        _controller.value = _controller.value.copyWith(
          selectedEntities: _controller._cachedInitList,
          previousSelection: false,
        );
      }
      _controller.galleryState.value = GalleryState.hide;
      Navigator.of(context).pop();
      return true;
    }

    final isPanelMax = panelController.value.state == SlidingState.max;

    if (!_controller.fullScreenMode && isPanelMax) {
      _controller.panelController.minimizePanel();
      return false;
    }

    return true;
  }

  // void _onSelectionClear() {
  //   _controller.clearSelection();
  //   Navigator.of(context).pop();
  // }

  void _onALbumChange(AssetPathEntity album) {
    if (_animationController.isAnimating) return;
    _controller._repository.fetchAssetsFor(album);
    _toogleAlbumList(true);
  }

  @override
  Widget build(BuildContext context) {
    _controller._cachedInitList = _controller.value.selectedEntities;
    final ps = _controller.panelSetting;
    final hs = _controller.headerSetting;
    final _panelMaxHeight =
        ps.maxHeight ?? MediaQuery.of(context).size.height - hs.topMargin;
    final _headerSetting = hs;

    final albumListHeight = _panelMaxHeight - hs.headerMaxHeight;
    albumHeight = albumListHeight;

    final body = Stack(
      // fit: StackFit.expand,
      children: [
        // Header
        Align(
          alignment: Alignment.topCenter,
          child: GalleryHeader(
            controller: _controller,
            albumNotifier: _controller._albumNotifier,
            onClose: _onClosePressed,
            onAlbumToggle: _toogleAlbumList,
            albumVisibility: _controller._albumVisibility,
          ),
        ),

        // Body
        Column(
          children: [
            // Header space
            Builder(
              builder: (context) {
                if (_controller.fullScreenMode) {
                  return SizedBox(
                    height: _headerSetting.headerMaxHeight +
                        MediaQuery.of(context).padding.top,
                  );
                }

                return ValueListenableBuilder<SliderValue>(
                  valueListenable: panelController,
                  builder: (context, SliderValue value, child) {
                    final height = (_headerSetting.headerMinHeight +
                            (_headerSetting.headerMaxHeight -
                                    _headerSetting.headerMinHeight) *
                                value.factor *
                                1.2)
                        .clamp(
                      _headerSetting.headerMinHeight,
                      _headerSetting.headerMaxHeight,
                    );
                    return SizedBox(height: height);
                  },
                );
              },
            ),

            if (_controller.headerSetting.elevation != 0)
              // Divider
              Divider(
                color: Colors.black,
                thickness: 0,
                height: _controller.headerSetting.elevation,
              ),

            // Gallery grid
            Expanded(
              child: GalleryGridView(
                controller: _controller,
                entitiesNotifier: _controller._entitiesNotifier,
                panelController: _controller.panelController,
                onCameraRequest: _controller.openCamera,
                onSelect: _controller._select,
              ),
            ),
          ],
        ),

        // Send and edit button

        // GalleryAssetSelector(
        //   controller: _controller,
        //   onEdit: (e) {
        //     _controller._openPlayground(context, e);
        //   },
        //   onSubmit: _controller.completeTask,
        // ),

        // Album list
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final offsetY = _headerSetting.headerMaxHeight +
                (_controller.fullScreenMode
                    ? MediaQuery.of(context).padding.top
                    : 0) +
                (_panelMaxHeight - hs.headerMaxHeight) * (1 - _animation.value);
            return Visibility(
              visible: _animation.value > 0.0,
              child: Transform.translate(
                offset: Offset(0.0, offsetY),
                child: child,
              ),
            );
          },
          child: GalleryAlbumView(
            albumsNotifier: _controller._albumsNotifier,
            controller: _controller,
            onAlbumChange: _onALbumChange,
          ),
        ),

        //
      ],
    );
    return WillPopScope(
      onWillPop: _onClosePressed,
      child: _controller.fullScreenMode
          ? Scaffold(
              backgroundColor: Colors.transparent,
              body: body,
            )
          : body,
    );
  }
}

///
///
///
///
///
///
class GalleryViewField extends StatefulWidget {
  ///
  /// Widget which pick media from gallery
  ///
  /// If used [GalleryViewField] with [GalleryViewWrapper], [PanelSetting]
  /// and [GallerySetting] will be override by the [GalleryViewWrapper]
  ///
  const GalleryViewField({
    Key? key,
    this.onChanged,
    this.onSubmitted,
    this.selectedEntities,
    required this.controller,
    // this.gallerySetting,
    this.child,
    this.previewBuilder,
    this.previewSize,
  }) : super(key: key);

  ///
  /// While picking likk using gallery removed will be true if,
  /// previously selected likk is unselected otherwise false.
  ///
  final void Function(LikkEntity entity, bool removed)? onChanged;

  ///
  /// Triggered when picker complet its task.
  ///
  final void Function(List<LikkEntity> entities)? onSubmitted;

  ///
  /// Pre selected entities
  ///
  final List<LikkEntity>? selectedEntities;

  ///
  /// If used [GalleryViewField] with [GalleryViewWrapper]
  /// this setting will be ignored.
  ///
  /// [GalleryController] passed to the [GalleryViewWrapper] will be applicable..
  /// ///
  final GalleryController controller;

  // ///
  // /// If used [GalleryViewField] with [GalleryViewWrapper]
  // /// this setting will be ignored.
  // ///
  // /// [PanelSetting] passed to the [GalleryViewWrapper] will be applicable..
  // ///
  // final PanelSetting? panelSetting;

  // ///
  // /// If used [GalleryViewField] with [GalleryViewWrapper]
  // /// this setting will be ignored.
  // ///
  // /// [GallerySetting] passed to the [GalleryViewWrapper] will be applicable..
  // ///
  // final GallerySetting? gallerySetting;

  ///
  final Widget? child;

  ///
  final Widget Function(Uint8List bytes)? previewBuilder;

  ///
  final Size? previewSize;

  @override
  _GalleryViewFieldState createState() => _GalleryViewFieldState();
}

class _GalleryViewFieldState extends State<GalleryViewField> {
  late GalleryController _controller;
  bool _dispose = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback(_init);
  }

  void _init(Duration timeStamp) {
    if (context.galleryController == null) {
      // _controller = GalleryController(
      //   panelSetting: widget.panelSetting,
      //   gallerySetting: widget.gallerySetting,
      // );
      _controller = widget.controller;
      _dispose = true;
    } else {
      _controller = context.galleryController!;
    }
  }

  // @override
  // void dispose() {
  //   if (_dispose) {
  //     _controller.dispose();
  //   }
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller._openGallery(
          widget.onChanged,
          widget.onSubmitted,
          widget.selectedEntities,
          context,
        );
      },
      child: widget.previewBuilder != null &&
              (_controller.recentEntities?.isNotEmpty ?? false)
          ? GalleryRecentPreview(
              entity: _controller.recentEntities!.first,
              builder: widget.previewBuilder,
              height: widget.previewSize?.height,
              width: widget.previewSize?.width,
              child: widget.child,
            )
          : widget.child,
    );
  }
}

///
///
///
///
///
///
class GalleryController extends ValueNotifier<GalleryValue> {
  ///
  /// Likk controller
  GalleryController({
    PanelSetting? panelSetting,
    HeaderSetting? headerSetting,
    GallerySetting? gallerySetting,
  })  : panelSetting = panelSetting ?? const PanelSetting(),
        headerSetting = headerSetting ?? const HeaderSetting(),
        setting = gallerySetting ?? const GallerySetting(),
        panelController = PanelController(),
        _albumsNotifier = ValueNotifier(const BaseState()),
        _albumNotifier = ValueNotifier(const BaseState()),
        _entitiesNotifier = ValueNotifier(const BaseState()),
        _recentEntities = ValueNotifier(const BaseState()),
        _albumVisibility = ValueNotifier(false),
        super(const GalleryValue()) {
    _repository = GalleryRepository(
      albumsNotifier: _albumsNotifier,
      albumNotifier: _albumNotifier,
      entitiesNotifier: _entitiesNotifier,
      recentEntitiesNotifier: _recentEntities,
    );
  }

  /// Panel setting
  final PanelSetting panelSetting;

  /// Header setting
  final HeaderSetting headerSetting;

  /// Media setting
  late final GallerySetting setting;

  /// Panel controller
  final PanelController panelController;

  /// Likk repository
  late final GalleryRepository _repository;

  /// Albums notifier
  final ValueNotifier<AlbumsType> _albumsNotifier;

  /// Current album notifier
  final ValueNotifier<AlbumType> _albumNotifier;

  /// Current album entities notifier
  final ValueNotifier<EntitiesType> _entitiesNotifier;

  /// Recent entities notifier
  final ValueNotifier<EntitiesType> _recentEntities;

  /// Recent entities notifier
  final ValueNotifier<bool> _albumVisibility;

  // Completer for gallerry picker controller
  Completer<List<LikkEntity>> _completer = Completer<List<LikkEntity>>();

  // Flag to handle updating controller value internally
  var _internal = false;

  // Flag for handling when user cleared all selected medias
  var _clearedSelection = false;

  // Gallery picker on changed event callback handler
  void Function(LikkEntity entity, bool removed)? _onChanged;

  //  Gallery picker on submitted event callback handler
  void Function(List<LikkEntity> entities)? _onSubmitted;

  // Full screen mode or collapsable mode
  var _fullScreenMode = false;

  var _accessCamera = false;

  final _wrapperKey = GlobalKey();

  List<LikkEntity> _cachedInitList = [];

  /// Recent entities notifier
  final ValueNotifier<GalleryState> galleryState =
      ValueNotifier(GalleryState.show);

  // ignore: public_member_api_docs
  bool get isShowPanel => panelController.isVisible;

  ///
  void _setAlbumVisibility(bool visible) {
    panelController.isGestureEnabled = !visible;
    _albumVisibility.value = visible;
  }

  /// Clear selected entities
  void clearSelection([List<LikkEntity>? list]) {
    if (list == null) {
      _onSubmitted?.call([]);
      _clearedSelection = true;
      _internal = true;
      value = const GalleryValue();
      return;
    }
    final _afterRemove = value.selectedEntities
      ..removeWhere((element) => list.contains(element));
    _onSubmitted?.call(_afterRemove);
    _clearedSelection = false;
    _internal = true;
    if (_afterRemove.isEmpty) {
      value = const GalleryValue();
      return;
    }

    value = value.copyWith(
      selectedEntities: _afterRemove,
      previousSelection: false,
    );
  }

  /// Selecting and unselecting entities
  Future<void> _select(LikkEntity entity, BuildContext context) async {
    final file = (await entity.entity.file)!;
    final size = await file.length();
    if (size > 25000000) return _onChanged?.call(entity, false);
    if (entity.entity.type == AssetType.video) {
      final extension = p.extension(file.path).toLowerCase();
      if (extension != '.mp4') {
        return _onChanged?.call(entity, false);
      }
    }
    final selectedList = value.selectedEntities.toList();
    if (singleSelection) {
      _clearedSelection = false;
      selectedList
        ..clear()
        ..add(entity);
      _onChanged?.call(entity, false);
    } else {
      _clearedSelection = false;
      if (selectedList.contains(entity)) {
        selectedList.remove(entity);
        _onChanged?.call(entity, true);
      } else {
        if (reachedMaximumLimit) {
          if (setting.onReachedMaximumLimit == null)
            // ignore: curly_braces_in_flow_control_structures
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                  content: Text(
                'Maximum selection limit of '
                '${setting.maximum} has been reached!',
              )));
          else {
            setting.onReachedMaximumLimit!();
          }
          return;
        }
        selectedList.add(entity);
        _onChanged?.call(entity, false);
      }
    }
    _internal = true;
    value = value.copyWith(
      selectedEntities: selectedList,
      previousSelection: false,
    );

    if (setting.onItemClick != null) {
      setting.onItemClick!(entity, selectedList);
    }
  }

  /// When selection is completed
  void completeTask(BuildContext context) {
    if (_fullScreenMode) {
      Navigator.of(context).pop(value.selectedEntities);
    } else {
      galleryState.value = GalleryState.hide;
      panelController.closePanel();
      // _checkKeyboard.value = false;
    }
    _onSubmitted?.call(value.selectedEntities);
    _completer.complete(value.selectedEntities);
    // _internal = true;
    // value = const GalleryValue();
  }

  /// close panel or page
  void close([BuildContext? context]) {
    if (!_fullScreenMode) {
      galleryState.value = GalleryState.hide;
      panelController.closePanel();
      return;
    }
    if (context != null) {
      Navigator.of(context).pop();
    }
  }

  /// When panel closed without any selection
  void _closePanel() {
    galleryState.value = GalleryState.hide;
    panelController.closePanel();
    final entities = (_clearedSelection || value.selectedEntities.isEmpty)
        ? <LikkEntity>[]
        : value.selectedEntities;
    _completer.complete(entities);
    // _onSubmitted?.call(entities);
    // _checkKeyboard.value = false;
    _internal = true;
    value = const GalleryValue();
  }

  /// Close collapsable panel if camera is selected from inside gallery view
  void _closeOnCameraSelect() {
    galleryState.value = GalleryState.hide;
    panelController.closePanel();
    // _checkKeyboard.value = false;
    _internal = true;
    value = const GalleryValue();
  }

  /// Open camera from [GalleryView]
  Future<LikkEntity?> openCamera(BuildContext context) async {
    _accessCamera = true;
    LikkEntity? entity;

    final route = SlideTransitionPageRoute<LikkEntity>(
      builder: const CameraView(),
      begainHorizontal: true,
      endHorizontal: false,
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (fullScreenMode) {
      entity = await Navigator.of(context).pushReplacement(route);
    } else {
      entity = await Navigator.of(context).push(route);
      _closeOnCameraSelect();
    }

    var entities = [...value.selectedEntities];
    if (entity != null) {
      entities.add(entity);
      _onChanged?.call(entity, false);
      _onSubmitted?.call(entities);
    }
    _accessCamera = false;
    _completer.complete(entities);
    return entity;
  }

  /// Open camera from [GalleryView]
  Future<void> _openPlayground(
    BuildContext context,
    LikkEntity entity,
  ) async {
    _select(entity, context);
    _accessCamera = true;
    LikkEntity? pickedEntity;

    final route = SlideTransitionPageRoute<LikkEntity>(
      builder: Playground(
        background: PhotoBackground(bytes: entity.bytes),
        enableOverlay: true,
      ),
      begainHorizontal: true,
      endHorizontal: false,
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (fullScreenMode) {
      pickedEntity = await Navigator.of(context).pushReplacement(route);
    } else {
      pickedEntity = await Navigator.of(context).push(route);
      _closeOnCameraSelect();
    }

    var entities = [...value.selectedEntities];
    if (pickedEntity != null) {
      entities.add(entity);
      _onChanged?.call(entity, false);
      _onSubmitted?.call(entities);
    }
    _accessCamera = false;
    _completer.complete(entities);
  }

  /// Open gallery using [GalleryViewField]
  void _openGallery(
    void Function(LikkEntity entity, bool removed)? onChanged,
    final void Function(List<LikkEntity> entities)? onSubmitted,
    List<LikkEntity>? selectedEntities,
    BuildContext context,
  ) {
    _onChanged = onChanged;
    _onSubmitted = onSubmitted;
    pick(context, selectedEntities: selectedEntities);
  }

  // ===================== PUBLIC ==========================

  /// Pick assets
  Future<List<LikkEntity>> pick(
    BuildContext context, {
    List<LikkEntity>? selectedEntities,
  }) async {
    // If dont have permission dont do anything
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission != PermissionState.authorized &&
        permission != PermissionState.limited) {
      PhotoManager.openSetting();
      return [];
    }

    _repository.fetchAlbums(setting.requestType);
    _completer = Completer<List<LikkEntity>>();
    galleryState.value = GalleryState.show;

    if (_wrapperKey.currentState == null) {
      _fullScreenMode = true;
      final route = SlideTransitionPageRoute<List<LikkEntity>>(
        builder: GalleryView(controller: this),
      );
      await Navigator.of(context).push(route).then((result) {
        // Closed by user
        if (result == null && !_accessCamera) {
          _completer.complete(value.selectedEntities);
        }
      });
    } else {
      _fullScreenMode = false;
      panelController.openPanel();
      FocusManager.instance.primaryFocus?.unfocus();
    }
    if (selectedEntities?.isNotEmpty ?? false) {
      _internal = true;
      value = value.copyWith(
        selectedEntities: selectedEntities,
        previousSelection: true,
      );
    }
    return _completer.future;
  }

  // ===================== GETTERS ==========================

  ///
  /// Recent entities list
  ///
  List<AssetEntity>? get recentEntities => _recentEntities.value.data;

  ///
  /// return true if gallery is in full screen mode,
  ///
  bool get fullScreenMode => _fullScreenMode;

  ///
  /// return true if selected media reached to maximum selection limit
  ///
  bool get reachedMaximumLimit =>
      value.selectedEntities.length == setting.maximum;

  ///
  /// return true is gallery is in single selection mode
  ///
  bool get singleSelection => setting.maximum == 1;

  @override
  set value(GalleryValue newValue) {
    if (_internal) {
      super.value = newValue;
      _internal = false;
    }
  }

  @override
  void dispose() {
    if (panelController.hasListeners) panelController.dispose();
    if (_albumsNotifier.hasListeners) _albumsNotifier.dispose();
    if (_albumNotifier.hasListeners) _albumNotifier.dispose();
    if (_entitiesNotifier.hasListeners) _entitiesNotifier.dispose();
    if (_recentEntities.hasListeners) _recentEntities.dispose();
    if (_albumVisibility.hasListeners) _albumVisibility.dispose();
    if (galleryState.hasListeners) galleryState.dispose();
    super.dispose();
  }

  //
}

/// State of panel
// ignore: public_member_api_docs
enum GalleryState { show, hide }
