function toIdList(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map(id => Number(id))
    .filter(id => !Number.isNaN(id));
}

function getClosedMerchantIds(groupData) {
  if (!groupData) {
    return [];
  }

  return toIdList(
    groupData.closed_cnl_cfg_ids ||
    groupData.close_cnl_cfg_ids ||
    groupData.close_cnl_ids ||
    groupData.closed_cnl_ids
  );
}

function buildOnlineCollectMerchants(groupData) {
  const closedIds = getClosedMerchantIds(groupData);

  return ((groupData && groupData.cnl_cfg_def) || []).map(item => ({
    ...item,
    onlineCollectEnabled: !closedIds.includes(Number(item.id)),
    savingOpenClose: false,
  }));
}

function applyOnlineCollectSaveSuccess(closedMerchantIds, merchantId, enabled) {
  const id = Number(merchantId);
  const closedIds = toIdList(closedMerchantIds);

  if (enabled) {
    return closedIds.filter(item => item !== id);
  }

  if (closedIds.includes(id)) {
    return closedIds;
  }

  return closedIds.concat(id);
}

function rollbackOnlineCollectMerchant(merchant, previousEnabled) {
  merchant.onlineCollectEnabled = previousEnabled;
  merchant.savingOpenClose = false;
}

module.exports = {
  buildOnlineCollectMerchants,
  getClosedMerchantIds,
  applyOnlineCollectSaveSuccess,
  rollbackOnlineCollectMerchant,
};
