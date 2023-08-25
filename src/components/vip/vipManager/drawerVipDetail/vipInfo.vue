<template>
  <div class="vip-info">
    <div class="form-grid">
      <div class="row">
        <div class="label">姓名:</div>
        <div class="value">{{info.name}}</div>
      </div>
      <div class="row">
        <div class="label">性别:</div>
        <div class="value">{{info.sex}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div class="value">{{info.bind_phone}}</div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{info.contact_phone}}</div>
      </div>
      <div class="row">
        <div class="label">出生日期:</div>
        <div class="value">{{info.birthday}}</div>
      </div>
      <div class="row">
        <div class="label">累计消费次数:</div>
        <div class="value">{{info.consume_cnt}}次</div>
      </div>
      <div class="row">
        <div class="label">累计消费金额:</div>
        <div class="value">{{info.consume_amt}}</div>
      </div>
      <div class="row">
        <div class="label">最后消费日期:</div>
        <div class="value">{{info.last_consume_day}}</div>
      </div>
    </div>
    <div class="row-another">
      <div class="label">消费喜好:</div>
      <div class="value">{{info.interest}}</div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {};
  },
  props: {
    info: {
      default: {}
    }
  },
};
</script>

<style scoped lang="less">
.vip-info {
  border-bottom: 1px solid #b0b7c6;
  padding-bottom: 20px;
  font-size: 14px;
  .form-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    grid-auto-rows: 28px;

    .row {
      display: grid;
      grid-template-columns: 120px 1fr;
    }
  }

  .label {
    text-align: right;
  }
  .value {
    margin-left: 10px;
    word-break: break-all;
  }

  .row-another {
    display: grid;
    grid-template-columns: 120px 1fr;
  }
}
</style>