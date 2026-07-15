import 'package:flutter/material.dart';
import 'base_view_model.dart';

class BaseView<T extends BaseViewModel> extends StatefulWidget {
  final Widget Function(BuildContext, T) onPageBuilder;
  final T viewModel;
  final Function(T)? onModelReady;
  final VoidCallback? onDispose;

  const BaseView({
    Key? key,
    required this.onPageBuilder,
    required this.viewModel,
    this.onModelReady,
    this.onDispose,
  }) : super(key: key);

  @override
  _BaseViewState<T> createState() => _BaseViewState<T>();
}

class _BaseViewState<T extends BaseViewModel> extends State<BaseView<T>> {
  late T viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.viewModel;

    if (widget.onModelReady != null) {
      widget.onModelReady!(viewModel);
    }

    viewModel.init();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose!();
    }

    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Since we're using a direct reference to the viewModel,
    // we don't need Provider/Consumer pattern here
    return widget.onPageBuilder(context, viewModel);
  }
}
