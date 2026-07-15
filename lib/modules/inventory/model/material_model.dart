class MaterialItem {
  final String code;
  final String description;
  final String? description2;
  final String unitOfMeasure;
  final int currentStock;
  final int actualStock;
  final int availableStock;
  final int committedStock;
  final String? itemGroup;
  final String? productCode;
  final String? supplierCode;
  final String? status;

  MaterialItem({
    required this.code,
    required this.description,
    this.description2,
    required this.unitOfMeasure,
    this.currentStock = 0,
    this.actualStock = 0,
    this.availableStock = 0,
    this.committedStock = 0,
    this.itemGroup,
    this.productCode,
    this.supplierCode,
    this.status,
  });

  // Create a sample list of materials for demonstration
  static List<MaterialItem> getSampleItems() {
    return [
      MaterialItem(
        code: '001000',
        description: 'SİGARA',
        unitOfMeasure: 'ADET',
        currentStock: 1,
        actualStock: 1,
        availableStock: 1,
      ),
      MaterialItem(
        code: '00126',
        description: 'FRESH %30%',
        unitOfMeasure: 'ADET',
        currentStock: 1,
        actualStock: 1,
        availableStock: 1,
      ),
      MaterialItem(
        code: '01234',
        description: 'LOCAT ALBINA ICE CUBE 1.5K',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '0251694764258',
        description: 'FAMILY KREM ŞANTI ÇILEK LT 20 GR',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '0251694764459',
        description: 'FAMILY KREM ŞANTI ÇİKOLATA 70 GR',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '0254444454004',
        description: 'FAMILY RAISINS 400G',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502841005',
        description: 'CANARY COCOA CREAM FILLED WAFERS 40g',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502964101',
        description: 'ACTIVE FOAM PLATES 10 * 26 CM',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502964118',
        description: 'ACTIVE FOAM PLATES 10 PSC 26 cm',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502964125',
        description: 'ACTIVE FOAM PLATES 10 PSC',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502964132',
        description: 'ACTIVE FOAM PLATES 10 PSC 22 cm',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253502971659',
        description: 'MUM BACKING POWDER 100G',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253503160033',
        description: 'SMARTEX TISSUES 200 PCS',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: 0,
        availableStock: 0,
      ),
      MaterialItem(
        code: '6253503460022',
        description: 'TIGER ENERGY DRINK CANS 250ML',
        unitOfMeasure: 'ADET',
        currentStock: 0,
        actualStock: -11,
        availableStock: -11,
      ),
    ];
  }

  // Convert list of MaterialItems to list of Maps for DataTableWidget
  static List<Map<String, dynamic>> toMapList(List<MaterialItem> items) {
    return items
        .map(
          (item) => {
            'code': item.code,
            'description': item.description,
            'description2': item.description2 ?? '',
            'unitOfMeasure': item.unitOfMeasure,
            'currentStock': item.currentStock,
            'actualStock': item.actualStock,
            'availableStock': item.availableStock,
            'committedStock': item.committedStock,
            'itemGroup': item.itemGroup ?? '',
            'productCode': item.productCode ?? '',
            'supplierCode': item.supplierCode ?? '',
            'status': item.status ?? '',
          },
        )
        .toList();
  }
}
