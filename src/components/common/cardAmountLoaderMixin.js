const needsDetails = (card) => card && [5, 6].includes(Number(card.bizStatus));

export default {
  data() {
    return {
      cardAmountDetails: {},
      cardAmountRefreshRevision: 0,
      cardAmountRefreshRunning: false,
      cardAmountStopped: false,
    };
  },
  methods: {
    cardAmountKey(card) {
      return JSON.stringify([
        this.$store.state.cardPageInfo.storeStatusId,
        card.seatId || card.id, card.wkCsmId, card.turnoverCnt,
        card.bizStatus, card.orderAmt, card.payedAmt, card.backAmt,
        card.yhAmt, card.yh2Amt,
      ]);
    },
    cardAmountTargets() {
      if (this.safeModeEnabled) return [];
      return (this.card.cardList || []).filter(needsDetails);
    },
    isCurrentCardAmount(key) {
      return !this.cardAmountStopped && this.cardAmountTargets().some((card) => this.cardAmountKey(card) === key);
    },
    async refreshCardAmounts() {
      if (this.cardAmountStopped) return;
      this.cardAmountRefreshRevision += 1;
      const keys = new Set(this.cardAmountTargets().map(this.cardAmountKey));
      Object.keys(this.cardAmountDetails).forEach((key) => {
        if (!keys.has(key)) this.$delete(this.cardAmountDetails, key);
      });
      // 合并刷新事件，最多同时读取三个可见的未结卡台。
      if (this.cardAmountRefreshRunning) return;
      this.cardAmountRefreshRunning = true;
      let completedRevision = -1;
      try {
        while (!this.cardAmountStopped && completedRevision !== this.cardAmountRefreshRevision) {
          completedRevision = this.cardAmountRefreshRevision;
          const targets = new Map();
          this.cardAmountTargets().forEach((card) => targets.set(this.cardAmountKey(card), card));
          const queue = Array.from(targets.entries());
          const worker = async () => {
            while (queue.length && !this.cardAmountStopped) {
              const [key, card] = queue.shift();
              if (!this.isCurrentCardAmount(key)) continue;
              try {
                const details = await this.fetchCardAmountDetails(card);
                if (!this.isCurrentCardAmount(key)) continue;
                if (details !== null && details !== undefined) {
                  this.$set(this.cardAmountDetails, key, details);
                } else {
                  this.$delete(this.cardAmountDetails, key);
                }
              } catch (error) {
                if (this.isCurrentCardAmount(key)) this.$delete(this.cardAmountDetails, key);
              }
            }
          };
          await Promise.all([worker(), worker(), worker()]);
        }
      } finally {
        this.cardAmountRefreshRunning = false;
      }
    },
  },
  watch: {
    "card.cardList": {
      handler() { this.refreshCardAmounts(); },
      immediate: true,
    },
    safeModeEnabled() { this.refreshCardAmounts(); },
  },
  beforeDestroy() {
    this.cardAmountStopped = true;
  },
};
