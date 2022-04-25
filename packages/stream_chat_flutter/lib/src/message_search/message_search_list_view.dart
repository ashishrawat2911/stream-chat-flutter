// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/src/message_search/query_progress_indicator.dart';
import 'package:stream_chat_flutter/src/utils/utils.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// {@template messageSearchListView}
/// Shows the list of searched messages.
///
/// ```dart
/// class MessageSearchPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: MessageSearchListView(
///         messageQuery: _channelQuery,
///         filters: {
///           'members': {
///             r'$in': [user.id]
///           }
///         },
///         limit: 20,
///       ),
///     );
///   }
/// }
/// ```
///
///
/// A [MessageSearchBloc] ancestor widget is required in order to provide the
/// information about the messages.
///
/// This widget uses a [ListView.separated] to render the list of messages.
///
/// The UI is rendered based on the first ancestor of type [StreamChatTheme].
/// Modify it to change the widget's appearance.
/// {@endtemplate}
@Deprecated('Use StreamMessageSearchListView instead')
class MessageSearchListView extends StatefulWidget {
  /// {@macro messageSearchListView}
  const MessageSearchListView({
    Key? key,
    required this.filters,
    this.messageQuery,
    this.sortOptions,
    this.limit = 30,
    this.messageFilters,
    this.separatorBuilder,
    this.itemBuilder,
    this.onItemTap,
    this.showResultCount = true,
    this.pullToRefresh = true,
    this.showErrorTile = false,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.childBuilder,
    this.messageSearchListController,
  }) : super(key: key);

  /// Message String to search on
  final String? messageQuery;

  /// The query filters to use.
  /// You can query on any of the custom fields you've defined on the [Channel].
  /// You can also filter other built-in channel fields.
  final Filter filters;

  /// The sorting used for the channels matching the filters.
  /// Sorting is based on field and direction, multiple sorting options
  /// can be provided.
  /// You can sort based on last_updated, last_message_at, updated_at,
  /// created_at or member_count.
  /// Direction can be ascending or descending.
  final List<SortOption>? sortOptions;

  /// The amount of messages requested per API call.
  final int limit;

  /// The message query filters to use.
  /// You can query on any of the custom fields you've defined on the [Channel].
  /// You can also filter other built-in channel fields.
  final Filter? messageFilters;

  /// {@macro messageSearchItemBuilder}
  final MessageSearchItemBuilder? itemBuilder;

  /// {@macro messageSearchItemTapCallback}
  final MessageSearchItemTapCallback? onItemTap;

  /// Builder used to create a custom item separator
  final IndexedWidgetBuilder? separatorBuilder;

  /// Set it to false to hide total results text
  final bool showResultCount;

  /// Set it to false to disable the pull-to-refresh widget
  final bool pullToRefresh;

  /// Show error tile on top
  final bool showErrorTile;

  /// The builder that is used when the search messages are fetched
  final Widget Function(List<GetMessageResponse>)? childBuilder;

  /// The builder used when the channel list is empty.
  final WidgetBuilder? emptyBuilder;

  /// The builder that will be used in case of error
  final ErrorBuilder? errorBuilder;

  /// The builder that will be used in case of loading
  final WidgetBuilder? loadingBuilder;

  /// A [MessageSearchListController] allows reloading and pagination.
  /// Use [MessageSearchListController.loadData] and
  /// [MessageSearchListController.paginateData] respectively for reloading and
  /// pagination.
  final MessageSearchListController? messageSearchListController;

  @override
  _MessageSearchListViewState createState() => _MessageSearchListViewState();
}

class _MessageSearchListViewState extends State<MessageSearchListView> {
  late final _defaultController = MessageSearchListController();

  MessageSearchListController get _messageSearchListController =>
      widget.messageSearchListController ?? _defaultController;

  @override
  Widget build(BuildContext context) {
    final messageSearchListCore = MessageSearchListCore(
      filters: widget.filters,
      sortOptions: widget.sortOptions,
      messageQuery: widget.messageQuery,
      limit: widget.limit,
      messageFilters: widget.messageFilters,
      messageSearchListController: _messageSearchListController,
      emptyBuilder: widget.emptyBuilder ??
          (context) {
            return LayoutBuilder(
              builder: (context, viewportConstraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Center(
                    child: Text(context.translations.emptyMessagesText),
                  ),
                ),
              ),
            );
          },
      errorBuilder: widget.errorBuilder ??
          (BuildContext context, dynamic error) {
            if (error is Error) {
              print(error.stackTrace);
            }
            return StreamInfoTile(
              showMessage: widget.showErrorTile,
              tileAnchor: Alignment.topCenter,
              childAnchor: Alignment.topCenter,
              message: context.translations.genericErrorText,
              child: const SizedBox.shrink(),
            );
          },
      loadingBuilder: widget.loadingBuilder ??
          (context) {
            return LayoutBuilder(
              builder: (context, viewportConstraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          },
      childBuilder: widget.childBuilder ?? _buildListView,
    );

    final backgroundColor =
        StreamMessageSearchListViewTheme.of(context).backgroundColor;

    if (backgroundColor != null) {
      return ColoredBox(
        color: backgroundColor,
        child: messageSearchListCore,
      );
    }

    return messageSearchListCore;
  }

  Widget _buildListView(List<GetMessageResponse> data) {
    final items = data;

    Widget child = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.isNotEmpty ? items.length + 1 : items.length,
      separatorBuilder: (_, index) {
        if (widget.separatorBuilder != null) {
          return widget.separatorBuilder!(context, index);
        }
        return Container(
          height: 1,
          color: StreamChatTheme.of(context).colorTheme.borders,
        );
      },
      itemBuilder: (context, index) {
        if (index < items.length) {
          if (widget.itemBuilder != null) {
            return widget.itemBuilder!(context, items[index]);
          }
          return StreamMessageSearchItem(
            getMessageResponse: items[index],
            onTap: () => widget.onItemTap!(items[index]),
          );
        }
        return const QueryProgressIndicator();
      },
    );
    if (widget.pullToRefresh) {
      child = RefreshIndicator(
        onRefresh: () => _messageSearchListController.loadData!(),
        child: child,
      );
    }

    child = LazyLoadScrollView(
      onEndOfPage: () => _messageSearchListController.paginateData!(),
      child: child,
    );

    if (widget.showResultCount) {
      final chatThemeData = StreamChatTheme.of(context);
      child = Column(
        children: [
          Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: chatThemeData.colorTheme.bgGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              child: Text(
                context.translations.resultCountText(items.length),
                style: TextStyle(
                  color: chatThemeData.colorTheme.textLowEmphasis,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    }
    return child;
  }
}
