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
  if (status === 1 || status === '1') {
    return Number(turnoverCnt) > 0;
  }

  return [4, 5, 6, 7].includes(Number(status));
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

function buildTurnoverTabs(tableNo, turnoverCnt) {
  const count = Number(turnoverCnt);
  const latestCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
  const tabCounts = latestCount > 0 ? Array.from({ length: latestCount }, (_, index) => latestCount - index) : [0];

  return tabCounts.map((currentTurnoverCnt) => ({
    turnoverCnt: currentTurnoverCnt,
    label: `${tableNo}-${String(currentTurnoverCnt || 1).padStart(3, '0')}`,
  }));
}

module.exports = {
  BOOKING_DETAIL_OPTION_IDS,
  normalizeBookingDetailConfig,
  getBookingDetailSaveFields,
  isBookingDetailStatusVisible,
  getBookingDetailOptionIds,
  buildTurnoverTabs,
};
