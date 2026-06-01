function toIdList(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map(id => Number(id))
    .filter(id => !Number.isNaN(id));
}

function findEntityGroup(groupData, entityId) {
  if (!groupData || !Array.isArray(groupData.cnl_cfg_grps)) {
    return null;
  }

  const id = Number(entityId);
  return groupData.cnl_cfg_grps.find(item => Number(item.id) === id) || null;
}

function readClosedIdsSource(data) {
  if (!data) {
    return undefined;
  }

  if (data.closed_cnl_cfg_ids !== undefined) return data.closed_cnl_cfg_ids;
  if (data.close_cnl_cfg_ids !== undefined) return data.close_cnl_cfg_ids;
  if (data.close_cnls !== undefined) return data.close_cnls;
  if (data.close_cnl_ids !== undefined) return data.close_cnl_ids;
  if (data.closed_cnl_ids !== undefined) return data.closed_cnl_ids;
  return undefined;
}

function getClosedMerchantIds(groupData, entityId) {
  if (!groupData) {
    return [];
  }

  const entityGroup = entityId ? findEntityGroup(groupData, entityId) : null;
  if (entityGroup) {
    const entityClosedSource = readClosedIdsSource(entityGroup);
    if (entityClosedSource !== undefined) {
      return toIdList(entityClosedSource);
    }
  }

  return toIdList(readClosedIdsSource(groupData));
}

function getEntityMerchantIds(groupData, entityId) {
  const entityGroup = findEntityGroup(groupData, entityId);
  if (!entityGroup) {
    return null;
  }

  return [Number(entityGroup.id)].concat(toIdList(entityGroup.sids));
}

function buildOnlineCollectMerchants(groupData, entityId) {
  const closedIds = getClosedMerchantIds(groupData, entityId);
  const entityMerchantIds = entityId ? getEntityMerchantIds(groupData, entityId) : null;

  return ((groupData && groupData.cnl_cfg_def) || [])
    .filter(item => !entityMerchantIds || entityMerchantIds.includes(Number(item.id)))
    .map(item => ({
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

function getOnlineCollectSaveParams(merchantId, enabled) {
  return {
    cnl_cfg_id: Number(merchantId),
    close: enabled ? 2 : 1,
  };
}

module.exports = {
  buildOnlineCollectMerchants,
  getClosedMerchantIds,
  findEntityGroup,
  getEntityMerchantIds,
  applyOnlineCollectSaveSuccess,
  rollbackOnlineCollectMerchant,
  getOnlineCollectSaveParams,
};
