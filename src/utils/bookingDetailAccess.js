const BOOKING_DETAIL_OPTION_IDS = Object.freeze({
  consumption: 26,
  wine: 27,
});

function isExactNumberOrString(value, expected) {
  return value === expected || value === String(expected);
}

function normalizeBookingDetailConfig(data = {}) {
  const source = data || {};
  const unrestricted = isExactNumberOrString(source.limit_book_csm_amt, 2);

  return {
    amountsRestricted: !unrestricted,
    consumptionEnabled: unrestricted && isExactNumberOrString(source.enable_book_csm_dtl, 1),
    wineEnabled: unrestricted && isExactNumberOrString(source.enable_book_wine_dtl, 1),
  };
}

function getBookingDetailSaveFields(state = {}) {
  const source = state || {};
  if (source.notShowAmt) {
    return {
      enable_book_csm_dtl: 2,
      enable_book_wine_dtl: 2,
    };
  }

  return {
    enable_book_csm_dtl: source.consumptionEnabled ? 1 : 2,
    enable_book_wine_dtl: source.wineEnabled ? 1 : 2,
  };
}

function isBookingDetailStatusVisible(status, turnoverCnt) {
  if ([1, 3, 8].includes(Number(status))) {
    return Number(turnoverCnt) > 0;
  }

  return [4, 5, 6, 7].includes(Number(status));
}

function getBookingDetailTurnoverCount(status, turnoverCnt) {
  const count = Number(turnoverCnt);
  const normalizedCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
  const currentTurnoverIsNotOpen = [1, 3, 7, 8].includes(Number(status));
  return currentTurnoverIsNotOpen ? Math.max(normalizedCount - 1, 0) : normalizedCount;
}

function getBookingDetailOptionIds(config = {}, status, turnoverCnt) {
  const source = config || {};
  if (source.amountsRestricted || !isBookingDetailStatusVisible(status, turnoverCnt)) {
    return [];
  }

  const optionIds = [];
  if (source.consumptionEnabled) optionIds.push(BOOKING_DETAIL_OPTION_IDS.consumption);
  if (source.wineEnabled) optionIds.push(BOOKING_DETAIL_OPTION_IDS.wine);
  return optionIds;
}

function buildTurnoverTabs(tableNo, turnoverCnt, status) {
  const count = Number(turnoverCnt);
  const latestCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
  const currentTurnoverIsOpen = [4, 5, 6].includes(Number(status));
  const tabCount = latestCount + (currentTurnoverIsOpen ? 1 : 0);
  const firstRequestCount = status === undefined
    ? latestCount
    : getBookingDetailTurnoverCount(status, latestCount);
  const tabCounts = tabCount > 0
    ? Array.from({ length: tabCount }, (_, index) => firstRequestCount - index)
    : [0];

  return tabCounts.map((currentTurnoverCnt, index) => ({
    turnoverCnt: currentTurnoverCnt,
    label: `${tableNo}-${String(tabCount > 0 ? tabCount - index : 1).padStart(3, '0')}`,
  }));
}

module.exports = {
  BOOKING_DETAIL_OPTION_IDS,
  normalizeBookingDetailConfig,
  getBookingDetailSaveFields,
  isBookingDetailStatusVisible,
  getBookingDetailOptionIds,
  buildTurnoverTabs,
  getBookingDetailTurnoverCount,
};
