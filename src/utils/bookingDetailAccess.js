const BOOKING_DETAIL_OPTION_IDS = {
  consumption: 26,
  wine: 27,
};

function isExactNumberOrString(value, expected) {
  return value === expected || value === String(expected);
}

function normalizeBookingDetailConfig(data = {}) {
  const unrestricted = isExactNumberOrString(data.limit_book_csm_amt, 2);

  return {
    amountsRestricted: !unrestricted,
    consumptionEnabled: unrestricted && isExactNumberOrString(data.enable_book_csm_dtl, 1),
    wineEnabled: unrestricted && isExactNumberOrString(data.enable_book_wine_dtl, 1),
  };
}

function getBookingDetailSaveFields(state = {}) {
  if (state.notShowAmt) {
    return {
      enable_book_csm_dtl: 2,
      enable_book_wine_dtl: 2,
    };
  }

  return {
    enable_book_csm_dtl: state.consumptionEnabled ? 1 : 2,
    enable_book_wine_dtl: state.wineEnabled ? 1 : 2,
  };
}

function isBookingDetailStatusVisible(status, turnoverCnt) {
  if (status === 1 || status === '1') {
    return Number(turnoverCnt) > 0;
  }

  return [4, 5, 6, 7].includes(Number(status));
}

function getBookingDetailOptionIds(config = {}, status, turnoverCnt) {
  if (config.amountsRestricted || !isBookingDetailStatusVisible(status, turnoverCnt)) {
    return [];
  }

  const optionIds = [];
  if (config.consumptionEnabled) optionIds.push(BOOKING_DETAIL_OPTION_IDS.consumption);
  if (config.wineEnabled) optionIds.push(BOOKING_DETAIL_OPTION_IDS.wine);
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
