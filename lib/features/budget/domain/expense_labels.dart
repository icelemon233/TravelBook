String expenseLabel(String key) =>
    const {
      'car': '车辆租赁',
      'fuel': '燃油',
      'hotels': '住宿',
      'meals': '餐饮',
      'tickets': '门票与景交',
      'insurance': '保险',
      'supplies': '应急物资',
      'camera': '拍摄设备',
      'hotel': '住宿',
      'food': '餐饮',
      'charging': '充电',
      'tolls': '高速费',
      'parking': '停车',
      'other': '其他',
    }[key] ??
    key;
