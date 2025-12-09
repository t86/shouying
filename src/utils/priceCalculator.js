/**
 * 商品价格计算工具
 * 根据卡台类型、会员状态、商务状态计算商品价格
 * 
 * 价格优先级: 商务包厢会员 > 商务包厢 > 商务会员 > 包厢会员 > 会员 > 商务 > 包厢 > 原价
 */

/**
 * 获取商品实际价格
 * @param {Object} productInfo - 商品信息
 * @param {Object} cardInfo - 卡台信息
 * @param {Object} businessData - 业务数据（14号元数据）
 * @param {Array} businessEmpList - 商务订位人列表（57号元数据）
 * @returns {string} 商品价格
 */
export function getProductPrice(productInfo, cardInfo, businessData, businessEmpList = []) {

  if (!productInfo) {
    return "0";
  }

  // 原价（必填）
  const originalPrice = productInfo.price || "0";
  
  // 如果商品类型是时价特饮、时价小费、时价赔偿，返回"时价"或0
  if ([3, 4, 5].includes(productInfo.prdType * 1)) {
    return "0";
  }

  // 判断是否为会员卡台：14号元数据有csm_cust_phone
  const isMemberCard = businessData && businessData.csm_cust_phone && businessData.csm_cust_phone.trim() !== "";
  
  // 判断是否为商务卡台：14号元数据的sales_emp_id在57号元数据范围内
  const salesEmpId = businessData ? (businessData.salesEmpId || businessData.sales_emp_id || businessData.sales_empId) : null;
  const isBusinessCard = salesEmpId && businessEmpList && businessEmpList.length > 0 && businessEmpList.some(emp => 
    emp.emp_id == salesEmpId && emp.status == 1
  );
  
  // 判断是否为包厢：卡台的seat_type=4
  const isBox = cardInfo && cardInfo.seatType == 4;

  // 获取价格字段（转换为数字，空字符串或0表示未配置）
  const mbPrice = parseFloat(productInfo.mbPrice || productInfo.mb_price || "0") || 0;
  const bsPrice = parseFloat(productInfo.bsPrice || productInfo.bs_price || "0") || 0;
  const bsMbPrice = parseFloat(productInfo.bsMbPrice || productInfo.bs_mb_price || "0") || 0;
  const bxPrice = parseFloat(productInfo.bxPrice || productInfo.bx_price || "0") || 0;
  const bxMbPrice = parseFloat(productInfo.bxMbPrice || productInfo.bx_mb_price || "0") || 0;
  const bxBsPrice = parseFloat(productInfo.bxBsPrice || productInfo.bx_bs_price || "0") || 0;
  const bxBsMbPrice = parseFloat(productInfo.bxBsMbPrice || productInfo.bx_bs_mb_price || "0") || 0;
  const origPrice = parseFloat(originalPrice) || 0;

  // 价格优先级: 商务包厢会员 > 商务包厢 > 商务会员 > 包厢会员 > 会员 > 商务 > 包厢 > 原价
  if (isBusinessCard && isBox && isMemberCard && bxBsMbPrice > 0) {
    return bxBsMbPrice.toString();
  }
  if (isBusinessCard && isBox && bxBsPrice > 0) {
    return bxBsPrice.toString();
  }
  if (isBusinessCard && isMemberCard && bsMbPrice > 0) {
    return bsMbPrice.toString();
  }
  if (isBox && isMemberCard && bxMbPrice > 0) {
    return bxMbPrice.toString();
  }
  if (isMemberCard && mbPrice > 0) {
    return mbPrice.toString();
  }
  if (isBusinessCard && bsPrice > 0) {
    return bsPrice.toString();
  }
  if (isBox && bxPrice > 0) {
    return bxPrice.toString();
  }
  
  // 默认返回原价
  return originalPrice;
}

/**
 * 获取商品显示价格（用于展示）
 * @param {Object} productInfo - 商品信息
 * @param {Object} cardInfo - 卡台信息
 * @param {Object} businessData - 业务数据（14号元数据）
 * @param {Array} businessEmpList - 商务订位人列表（57号元数据）
 * @returns {string} 商品显示价格（"时价"或价格字符串）
 */
export function getProductDisplayPrice(productInfo, cardInfo, businessData, businessEmpList = []) {
  if (!productInfo) {
    return "0";
  }

  // 如果商品类型是时价特饮、时价小费、时价赔偿，返回"时价"
  if ([3, 4, 5].includes(productInfo.prdType * 1)) {
    return "时价";
  }

  const price = getProductPrice(productInfo, cardInfo, businessData, businessEmpList);
  return price;
}

/**
 * 获取商品价格信息（用于展示原价和会员价）
 * @param {Object} productInfo - 商品信息
 * @param {Object} cardInfo - 卡台信息
 * @param {Object} businessData - 业务数据（14号元数据）
 * @param {Array} businessEmpList - 商务订位人列表（57号元数据）
 * @returns {Object} 价格信息对象 { originalPrice: string, memberPrice: string, hasMemberPrice: boolean, displayPrice: string }
 */
export function getProductPriceInfo(productInfo, cardInfo, businessData, businessEmpList = []) {
  if (!productInfo) {
    return {
      originalPrice: "0",
      memberPrice: "",
      hasMemberPrice: false,
      displayPrice: "0"
    };
  }

  // 原价（必填）
  const originalPrice = productInfo.price || "0";
  
  // 如果商品类型是时价特饮、时价小费、时价赔偿
  if ([3, 4, 5].includes(productInfo.prdType * 1)) {
    return {
      originalPrice: "0",
      memberPrice: "",
      hasMemberPrice: false,
      displayPrice: "时价"
    };
  }

  // 判断是否为会员卡台：14号元数据有csm_cust_phone
  const isMemberCard = businessData && businessData.csm_cust_phone && businessData.csm_cust_phone.trim() !== "";
  
  // 判断是否为商务卡台：14号元数据的sales_emp_id在57号元数据范围内
  const salesEmpId = businessData ? (businessData.salesEmpId || businessData.sales_emp_id || businessData.sales_empId) : null;
  const isBusinessCard = salesEmpId && businessEmpList && businessEmpList.length > 0 && businessEmpList.some(emp => 
    emp.emp_id == salesEmpId && emp.status == 1
  );
  
  // 判断是否为包厢：卡台的seat_type=4
  const isBox = cardInfo && cardInfo.seatType == 4;

  // 获取价格字段（转换为数字，空字符串或0表示未配置）
  const mbPrice = parseFloat(productInfo.mbPrice || productInfo.mb_price || "0") || 0;
  const bsPrice = parseFloat(productInfo.bsPrice || productInfo.bs_price || "0") || 0;
  const bsMbPrice = parseFloat(productInfo.bsMbPrice || productInfo.bs_mb_price || "0") || 0;
  const bxPrice = parseFloat(productInfo.bxPrice || productInfo.bx_price || "0") || 0;
  const bxMbPrice = parseFloat(productInfo.bxMbPrice || productInfo.bx_mb_price || "0") || 0;
  const bxBsPrice = parseFloat(productInfo.bxBsPrice || productInfo.bx_bs_price || "0") || 0;
  const bxBsMbPrice = parseFloat(productInfo.bxBsMbPrice || productInfo.bx_bs_mb_price || "0") || 0;
  const origPrice = parseFloat(originalPrice) || 0;

  // 价格优先级: 商务包厢会员 > 商务包厢 > 商务会员 > 包厢会员 > 会员 > 商务 > 包厢 > 原价
  // 根据优先级确定应该展示哪一组价格，并判断该组价格是否同时配置了原价和会员价
  
  if (isBusinessCard && isBox && isMemberCard) {
    // 商务包厢会员：检查是否同时配置了商务包厢原价和商务包厢会员价
    if (bxBsMbPrice > 0 && bxBsPrice > 0) {
      // 同时配置了商务包厢原价和商务包厢会员价，显示两个价格
      return {
        originalPrice: bxBsPrice.toString(),
        memberPrice: bxBsMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bxBsMbPrice.toString()
      };
    } else if (bxBsPrice > 0) {
      // 只配置了商务包厢原价，只显示一个价格
      return {
        originalPrice: bxBsPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bxBsPrice.toString()
      };
    }
  }
  
  if (isBusinessCard && isBox) {
    // 商务包厢：检查是否同时配置了商务包厢原价和商务包厢会员价
    if (bxBsMbPrice > 0 && bxBsPrice > 0) {
      // 同时配置了商务包厢原价和商务包厢会员价，显示两个价格
      return {
        originalPrice: bxBsPrice.toString(),
        memberPrice: bxBsMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bxBsMbPrice.toString()
      };
    } else if (bxBsPrice > 0) {
      // 只配置了商务包厢原价，只显示一个价格
      return {
        originalPrice: bxBsPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bxBsPrice.toString()
      };
    }
  }
  
  if (isBusinessCard && isMemberCard) {
    // 商务会员：检查是否同时配置了商务原价和商务会员价
    if (bsMbPrice > 0 && bsPrice > 0) {
      // 同时配置了商务原价和商务会员价，显示两个价格
      return {
        originalPrice: bsPrice.toString(),
        memberPrice: bsMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bsMbPrice.toString()
      };
    } else if (bsPrice > 0) {
      // 只配置了商务原价，只显示一个价格
      return {
        originalPrice: bsPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bsPrice.toString()
      };
    }
  }
  
  if (isBox && isMemberCard) {
    // 包厢会员：检查是否同时配置了包厢原价和包厢会员价
    if (bxMbPrice > 0 && bxPrice > 0) {
      // 同时配置了包厢原价和包厢会员价，显示两个价格
      return {
        originalPrice: bxPrice.toString(),
        memberPrice: bxMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bxMbPrice.toString()
      };
    } else if (bxPrice > 0) {
      // 只配置了包厢原价，只显示一个价格
      return {
        originalPrice: bxPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bxPrice.toString()
      };
    }
  }
  
  if (isMemberCard) {
    // 会员卡台：检查是否同时配置了原价和会员价
    if (mbPrice > 0 && origPrice > 0) {
      // 同时配置了原价和会员价，显示两个价格
      return {
        originalPrice: originalPrice,
        memberPrice: mbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: mbPrice.toString()
      };
    } else if (mbPrice > 0) {
      // 只配置了会员价，只显示一个价格
      return {
        originalPrice: originalPrice,
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: mbPrice.toString()
      };
    } else {
      // 会员卡台但没有配置会员价，只显示原价
      return {
        originalPrice: originalPrice,
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: originalPrice
      };
    }
  }
  
  if (isBusinessCard) {
    // 商务卡台：检查是否同时配置了商务原价和商务会员价
    if (bsMbPrice > 0 && bsPrice > 0) {
      // 同时配置了商务原价和商务会员价，显示两个价格
      return {
        originalPrice: bsPrice.toString(),
        memberPrice: bsMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bsMbPrice.toString()
      };
    } else if (bsPrice > 0) {
      // 只配置了商务原价，只显示一个价格
      return {
        originalPrice: bsPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bsPrice.toString()
      };
    }
  }
  
  if (isBox) {
    // 包厢卡台：检查是否同时配置了包厢原价和包厢会员价
    if (bxMbPrice > 0 && bxPrice > 0) {
      // 同时配置了包厢原价和包厢会员价，显示两个价格
      return {
        originalPrice: bxPrice.toString(),
        memberPrice: bxMbPrice.toString(),
        hasMemberPrice: true,
        displayPrice: bxMbPrice.toString()
      };
    } else if (bxPrice > 0) {
      // 只配置了包厢原价，只显示一个价格
      return {
        originalPrice: bxPrice.toString(),
        memberPrice: "",
        hasMemberPrice: false,
        displayPrice: bxPrice.toString()
      };
    }
  }
  
  // 默认情况：普通卡台，检查是否同时配置了原价和会员价
  // 如果同时配置了原价和会员价，显示两个价格（原价+会员价）
  if (mbPrice > 0 && origPrice > 0) {
    return {
      originalPrice: originalPrice,
      memberPrice: mbPrice.toString(),
      hasMemberPrice: true,
      displayPrice: originalPrice // 非会员卡台显示原价
    };
  }
  
  // 默认返回原价
  return {
    originalPrice: originalPrice,
    memberPrice: "",
    hasMemberPrice: false,
    displayPrice: originalPrice
  };
}

