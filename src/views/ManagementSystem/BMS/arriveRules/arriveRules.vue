<template>
  <!-- 计抵达规则 -->
  <div class="arrive-rules">
    <div class="coll border-bottom p-b-5" layout="row" layout-align="start center">
      <div class="label">
        <span>计抵达规则：</span>
      </div>
      <div class="value" layout="row" layout-align="start center">
        <span>门店消费金额大于等于</span>
        <el-input
          class="m-l-2 m-r-2"
          v-model="amt"
          placeholder="请输入金额"
          size="small"
          style="width:100px"
        ></el-input>
        <span>计抵达</span>
      </div>
    </div>

    <div class="area-content">
      <div class="tips p-t-3 p-b-3"><span class="red-color" style="font-weight:600">不计抵达</span>卡台配置</div>
      <div class="area-contain">
        <div class="area-list" v-for="item in areaList" :key="item.id">
          <h3 class="area-name m-t-3 m-b-3">
            <span class="m-r-3">{{item.n}}</span>
          </h3>
          <div class="seat-list" layout="row" layout-align="start start">
            <div
              class="item cursor"
              :class="{'active': items.checked, 'choose': items.t != 3}"
              v-for="items in item.ss"
              :key="items.id"
              @click="chooseSeatHandle(items)"
            >
              <div class="item-name fs18">{{items.n}}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="btn-area">
      <el-button type="primary" class="m-l-10 m-t-5" @click.native="onSubmitHandle">保存</el-button>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      amt: "",
      areaList: []
    };
  },
  methods: {
    async getData(){
      try {
        const res = await this.$api.BMS.arriveRules.reqGetSeatConfig()
        if(res.code == 1) {
          this.amt = res.data.min_amt || 0
          this.areaList = (res.data.region_seats || []).map(item => ({
            ...item,
            ss: (item.ss || []).map(items => ({
              ...items,
              checked: items.t == 1 || items.t == 3  //  1  已选中  2 未选中  3 固定选中项(类似虚拟,补交台默认选中,不能取消)
            }))
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    async onSubmitHandle(){
      const seatIds = []
      this.areaList.forEach(el => {
        el.ss.forEach(ele => {
          if(ele.checked && ele.t != 3) {
            seatIds.push(ele.id)
          }
        })
      })
      const params = {
        min_amt: this.amt * 1, //    int     计抵达最小金额(主营未结账金额+主营已结账折后)
        seat_ids: seatIds, //   []int64    勾选的不计抵达的卡台Id列表
      }
      try {
        const res = await this.$api.BMS.arriveRules.reqSetSeatConfig(params)
        if(res.code == 1) {
          this.$message.success('保存成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    chooseSeatHandle(itemInfo){
      if(itemInfo.t == 3) return this.$message.warning('虚拟台、关联台不允许取消选中')
      itemInfo.checked = !itemInfo.checked
    }
  },
  created() {
    this.getData()
  },
};
</script>

<style scoped lang='less'>
.arrive-rules {
  font-size: 14px;
  padding: 20px;
  box-sizing: border-box;
  overflow-y: auto;

  .border-bottom {
    border-bottom: 1px solid #ccc;
  }

  .area-content {
    box-sizing: border-box;
    .area-contain{
      max-height: calc(100vh - 270px);
      overflow: auto;
    }
    .seat-list {
      flex-wrap: wrap;
      .item {
        width: 100px;
        height: 56px;
        border: 1px solid #999;
        border-radius: 8px;
        margin: 6px;
        padding: 8px 10px;
        box-sizing: border-box;

        &.active {
          position: relative;
          background-color: #409eff;
          border-color: #409eff;
          color: #fff;
          &.choose:after {
            position: absolute;
            right: 2px;
            top: 2px;
            padding: 2px;
            content: "√";
            border: 1px solid yellow;
            color: yellow;
            border-radius: 50%;
            transform: rotate(10deg);
          }
        }

        .item-merchant {
          margin-top: 2px;
          text-align: right;
        }
      }
    }
  }
}
</style>