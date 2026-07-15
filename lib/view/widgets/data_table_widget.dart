import 'package:flutter/material.dart';

class DataTableWidget extends StatefulWidget {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final Function(Map<String, dynamic>)? onRowTap;
  final Function(Map<String, dynamic>)? onRowDoubleTap;
  final Function(String)? onSort;
  final bool showRowNumbers;
  final bool enableSearch;
  final bool enableColumnResize;
  final bool enableColumnReordering;
  final bool enableFiltering;
  final bool enableMultiSelect;
  final int? selectedRowIndex;
  final List<int>? selectedRowIndexes;
  final void Function(int)? onRowSelected;

  const DataTableWidget({
    Key? key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onSort,
    this.showRowNumbers = true,
    this.enableSearch = true,
    this.enableColumnResize = true,
    this.enableColumnReordering = false,
    this.enableFiltering = true,
    this.enableMultiSelect = false,
    this.selectedRowIndex,
    this.selectedRowIndexes,
    this.onRowSelected,
  }) : super(key: key);

  @override
  DataTableWidgetState createState() => DataTableWidgetState();
}

class DataTableWidgetState extends State<DataTableWidget> {
  late List<double> columnWidths;
  int? hoveredRowIndex;
  int? _selectedRowIndex;
  List<int> _selectedRowIndexes = [];
  String _searchQuery = '';
  List<Map<String, dynamic>> filteredRows = [];
  String _sortColumnKey = '';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _initializeColumnWidths();
    _selectedRowIndex = widget.selectedRowIndex;
    _selectedRowIndexes = widget.selectedRowIndexes ?? [];
    filteredRows = List.from(widget.rows);
    _applyFiltering();
  }

  @override
  void didUpdateWidget(DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      filteredRows = List.from(widget.rows);
      _applyFiltering();
    }
    if (oldWidget.columns.length != widget.columns.length) {
      _initializeColumnWidths();
    }
    if (oldWidget.selectedRowIndex != widget.selectedRowIndex) {
      _selectedRowIndex = widget.selectedRowIndex;
    }
  }

  void _initializeColumnWidths() {
    // Initialize column widths with default values
    int columnCount = widget.columns.length + (widget.showRowNumbers ? 1 : 0);
    columnWidths = List.filled(columnCount, 120);

    // Set row number column to be narrower
    if (widget.showRowNumbers) {
      columnWidths[0] = 50;
    }
  }

  void _applyFiltering() {
    if (_searchQuery.isEmpty) {
      filteredRows = List.from(widget.rows);
    } else {
      final query = _searchQuery.toLowerCase();
      filteredRows =
          widget.rows.where((row) {
            return widget.columns.any((column) {
              final value = row[column]?.toString().toLowerCase() ?? '';
              return value.contains(query);
            });
          }).toList();
    }

    // Apply sorting if needed
    if (_sortColumnKey.isNotEmpty) {
      _applySorting(_sortColumnKey, _sortAscending);
    }
  }

  void _applySorting(String columnKey, bool ascending) {
    _sortColumnKey = columnKey;
    _sortAscending = ascending;

    filteredRows.sort((a, b) {
      final aValue = a[columnKey];
      final bValue = b[columnKey];

      // Handle null values
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      // Compare based on type
      if (aValue is num && bValue is num) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is String && bValue is String) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        // Default to string comparison
        return ascending
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.enableSearch) _buildSearchBar(),
        Expanded(child: _buildDataTable()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _applyFiltering();
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 8,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFiltering();
          });
        },
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            // Header row
            Container(
              color: const Color(0xFFE8EAF6),
              child: Row(
                children: [
                  if (widget.showRowNumbers)
                    _buildHeaderCell('#', columnWidths[0], -1),
                  ...List.generate(widget.columns.length, (index) {
                    final columnIndex =
                        widget.showRowNumbers ? index + 1 : index;
                    return _buildHeaderCell(
                      widget.columns[index],
                      columnWidths[columnIndex],
                      index,
                    );
                  }),
                ],
              ),
            ),
            // Data rows
            Expanded(
              child:
                  filteredRows.isEmpty
                      ? const Center(child: Text('Veri bulunamadı'))
                      : ListView.builder(
                        itemCount: filteredRows.length,
                        itemBuilder: (context, index) {
                          final isSelected =
                              widget.enableMultiSelect
                                  ? _selectedRowIndexes.contains(index)
                                  : _selectedRowIndex == index;
                          final isHovered = hoveredRowIndex == index;

                          return MouseRegion(
                            onEnter:
                                (_) => setState(() => hoveredRowIndex = index),
                            onExit:
                                (_) => setState(() => hoveredRowIndex = null),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (widget.enableMultiSelect) {
                                    if (_selectedRowIndexes.contains(index)) {
                                      _selectedRowIndexes.remove(index);
                                    } else {
                                      _selectedRowIndexes.add(index);
                                    }
                                  } else {
                                    _selectedRowIndex = index;
                                  }
                                });

                                if (widget.onRowSelected != null) {
                                  widget.onRowSelected!(index);
                                }

                                if (widget.onRowTap != null) {
                                  widget.onRowTap!(filteredRows[index]);
                                }
                              },
                              onDoubleTap: () {
                                if (widget.onRowDoubleTap != null) {
                                  widget.onRowDoubleTap!(filteredRows[index]);
                                }
                              },
                              child: Container(
                                color:
                                    isSelected
                                        ? const Color(
                                          0xFFCFD8DC,
                                        ) // Selected row color
                                        : isHovered
                                        ? const Color(
                                          0xFFE1F5FE,
                                        ) // Hovered row color
                                        : index.isEven
                                        ? Colors.white
                                        : const Color(
                                          0xFFF5F5F5,
                                        ), // Alternating row colors
                                child: Row(
                                  children: [
                                    if (widget.showRowNumbers)
                                      _buildCell(
                                        (index + 1).toString(),
                                        columnWidths[0],
                                      ),
                                    ...List.generate(widget.columns.length, (
                                      colIndex,
                                    ) {
                                      final columnIndex =
                                          widget.showRowNumbers
                                              ? colIndex + 1
                                              : colIndex;
                                      final value =
                                          filteredRows[index][widget
                                                  .columns[colIndex]]
                                              ?.toString() ??
                                          '';
                                      return _buildCell(
                                        value,
                                        columnWidths[columnIndex],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width, int columnIndex) {
    return GestureDetector(
      onTap: () {
        if (columnIndex >= 0) {
          final columnKey = widget.columns[columnIndex];
          // Toggle sort direction if already sorting by this column
          final ascending =
              _sortColumnKey == columnKey ? !_sortAscending : true;
          setState(() {
            _applySorting(columnKey, ascending);
          });
          if (widget.onSort != null) {
            widget.onSort!(columnKey);
          }
        }
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade400),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (columnIndex >= 0 &&
                _sortColumnKey == widget.columns[columnIndex])
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: Colors.grey.shade700,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width) {
    return Container(
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
