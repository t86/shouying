<template>
  <div class="search-detail p-t-4">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号:</div>
        <div class="value">{{ vipInfo.card_no }}</div>
      </div>
      <div class="row">
        <div class="label">会员卡等级:</div>
        <div class="value">{{ vipInfo.card_level_name }}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机:</div>
        <div class="value">{{ vipInfo.bind_phone }}</div>
      </div>
      <div class="row">
        <div class="label">联系手机:</div>
        <div class="value">{{ vipInfo.contact_phone }}</div>
      </div>
      <div class="row">
        <div class="label">姓名:</div>
        <div class="value">{{ vipInfo.name }}</div>
      </div>
      <div class="row">
        <div class="label">卡类型:</div>
        <div class="value">{{ vipInfo.card_type_name }}</div>
      </div>
      <div class="row">
        <div class="label">会员卡标签:</div>
        <div class="value">{{ vipInfo.mark }}</div>
      </div>
      <div class="row">
        <div class="label">会员卡总余额:</div>
        <div class="value">{{ vipInfo.bal }}</div>
      </div>
      <div class="row">
        <div class="label">储值余额:</div>
        <div class="value">{{ vipInfo.val_bal }}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额:</div>
        <div class="value">{{ vipInfo.free_bal }}</div>
      </div>
      <!-- <div class="row">
        <div class="label">剩余积分:</div>
        <div class="value">00001</div>
      </div>-->
    </div>
    <div class="form">
      <div class="row">
        <div class="label m-t-2">
          <span class="red">*</span>
          <span>选择充值详情:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <div
            class="item"
            :class="{ active: index == form.activeDetailId }"
            v-for="(item, index) in makeMoneyList"
            :key="index"
            layout="column"
            layout-align="center center"
            @click="form.activeDetailId = index"
          >
            <div class="item-top">
              <span>¥</span>
              {{ isNaN(item.d) ? item.d : (item.d / 100).toFixed(2)}}
            </div>
            <div class="item-bottom" v-if="item.f * 1 > 0">
              赠 ¥ {{ (item.f/100).toFixed(2) }}
            </div>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="label ">
          <span>赠送积分:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
         {{sendPoint == 0?'---':sendPoint}}
        </div>
      </div>
      <div class="row">
        <div class="label ">
          <span>赠送卡券:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
         {{form.activeDetailId >= depositRules.length ? '---':depositRules[form.activeDetailId].kn }}
        </div>
      </div>
      <div class="row" v-if="form.activeDetailId == makeMoneyList.length - 1">
        <div class="label m-t-2">
          <span>充值金额:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input
            v-model="form.makeAmt"
            size="small"
            style="width: 284px"
            placeholder="请输入充值金额"
          ></el-input>
        </div>
      </div>
      <div class="row" v-if="form.activeDetailId == makeMoneyList.length - 1">
        <div class="label m-t-2">
          <span>赠送金额:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input
            v-model="form.freeAmt"
            size="small"
            style="width: 284px"
            placeholder="请输入赠送金额"
          ></el-input>
        </div>
      </div>
      <div class="row">
        <div class="label m-t-2">
          <span class="red">*</span>
          <span>充值方式:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-select
            v-model="form.typeVal"
            size="small"
            style="width: 284px"
            placeholder="请选择充值方式"
          >
            <el-option
              v-for="item in typeOption"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <div class="row">
        <div class="label m-t-2">
          <span>充卡推荐人:</span>
        </div>
        <div class="value">
          <el-select
            style="width: 284px"
            v-model="form.personVal"
            filterable
            remote
            reserve-keyword
            placeholder="输入员工姓名或工号可查询"
            :remote-method="remoteMethod"
            :loading="remoteLoading"
            size="small"
          >
            <el-option
              v-for="item in personOptions"
              :key="item.id"
              :label="item.name + ' (' + item.code + ')'"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <div class="row">
        <div class="label m-t-2">
          <span>备注:</span>
        </div>
        <div class="value">
          <el-input
            type="textarea"
            :rows="2"
            placeholder="请输入备注"
            v-model="form.remark"
            style="width: 284px"
          ></el-input>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      vipInfo: {},
      makeMoneyList: [], // 充值详情
      typeOption: [], // 充值方式
      depositRules: [], // 充值规则
      remoteLoading: false,
      personOptions: [], // 充值推荐人
      form: {
        activeDetailId: 0, // 选择充值详情id
        typeVal: "", // 充值方式
        personVal: "",
        remark: "",
        makeAmt: "",
        freeAmt: "",
      },
      base_amt:0, // 充值赠送积分基数, =0代表不赠送, =10代表充值有价金额每满10元赠送1个积分
    };
  },
  methods: {
    init() {
      const id = this.currentInfo.id
        ? this.currentInfo.id
        : this.vipIdOfSwiper * 1;
      this.getVipDetailInfo(id);
    },
    // 获取vip详情
    async getVipDetailInfo(id) {
      const params = {
        id: id * 1, //   int64   会员卡Id
      };
      try {
        const res = await api_vip.reqGetVipCardDetailForMakeMoney(params);
        if (res.code == 1) {
          this.vipInfo = res.data.mb_card;
          console.log("会员卡信息:", this.vipInfo);
          console.log("会员卡 sales_emp_id:", this.vipInfo.sales_emp_id);
          
          this.makeMoneyList = [
            ...(res.data.deposit_rules || []),
            { d: "自定义", f: 0 },
          ];
          
          // 获取所有推荐人列表
          const result =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
          console.log("Store 中的推荐人列表:", result);
          this.personOptions = result;
          
          // 按照三层规则设置推荐人
          await this.setRecommenderByRules(this.vipInfo.id, this.vipInfo.sales_emp_id);
          
          console.log("最终设置的推荐人:", this.form.personVal);
          this.typeOption = res.data.depoist_cnls || [];
          this.depositRules = res.data.deposit_rules || [];
          this.base_amt = res.data.base_amt;
          console.log("获取充值前会员卡信息成功", this.depositRules);
          console.log("充值渠道列表:", this.typeOption);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取充值前会员卡信息失败", error);
      }
    },

    // 按照三层规则设置推荐人
    async setRecommenderByRules(cardId, openCardSalesEmpId) {
      try {
        console.log("开始按规则设置推荐人，卡ID:", cardId, "开卡推荐人ID:", openCardSalesEmpId);
        
        // 第一层：查询该卡上次充值时的充值推荐人
        const params = {
          card_id: cardId
        };
        const res = await api_vip.reqGetCustCardLastSales(params);
        console.log("上次充值推荐人接口返回:", res);
        
        if (res.code == 1 && res.data && res.data.id) {
          const lastRechargeSalesEmpId = res.data.id;
          console.log("第一层：找到上次充值推荐人ID:", lastRechargeSalesEmpId, "姓名:", res.data.name);
          
          // 尝试在推荐人列表中找到匹配的推荐人
          const matchedPerson = this.findPersonInOptions(lastRechargeSalesEmpId);
          if (matchedPerson) {
            this.form.personVal = matchedPerson.id;
            console.log("第一层：设置上次充值推荐人为默认值:", this.form.personVal);
            return;
          } else {
            console.log("第一层：上次充值推荐人不在当前推荐人列表中");
          }
        } else {
          console.log("第一层：没有找到上次充值推荐人");
        }
        
        // 第二层：如果没有上次充值推荐人，则使用开卡推荐人
        if (openCardSalesEmpId) {
          console.log("第二层：尝试使用开卡推荐人ID:", openCardSalesEmpId);
          const matchedPerson = this.findPersonInOptions(openCardSalesEmpId);
          if (matchedPerson) {
            this.form.personVal = matchedPerson.id;
            console.log("第二层：设置开卡推荐人为默认值:", this.form.personVal);
            return;
          } else {
            console.log("第二层：开卡推荐人不在当前推荐人列表中");
          }
        } else {
          console.log("第二层：没有开卡推荐人信息");
        }
        
        // 第三层：如果前两层都没有，则推荐人为空白
        console.log("第三层：推荐人设置为空白，允许用户手动选择");
        this.form.personVal = "";
        
      } catch (error) {
        console.error("设置推荐人失败:", error);
        this.form.personVal = "";
      }
    },
    
    // 在推荐人选项中查找指定ID的推荐人
    findPersonInOptions(salesEmpId) {
      if (!salesEmpId) return null;
      
      const salesEmpIdStr = salesEmpId.toString();
      return this.personOptions.find(person => 
        person.id.toString() === salesEmpIdStr || 
        person.id.includes(salesEmpIdStr)
      );
    },

    remoteMethod(query) {
      if (query !== "") {
        this.remoteLoading = true;
        const result =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.personOptions = result.filter(
          (item) => item.code.includes(query) || item.name.includes(query) || item.namePy.includes(query)
        );
        this.remoteLoading = false;
      } else {
        this.options = [];
      }
    },
  },
  props: {
    currentInfo: {
      default: () => {},
    },
    vipIdOfSwiper: {
      default: "",
    },
  },
  watch: {
    form: {
      handler(newVal) {
        this.$emit("updateFormInfo", {
          ...newVal,
          sendPoint:this.sendPoint,
          makeAmtInfo:
            this.makeMoneyList.length > 0
              ? this.makeMoneyList[this.form.activeDetailId]
              : {},
        });
      },
      deep: true,
      immediate: true,
    },
  },
  computed:{
    sendPoint(){
       let point = "";
       if(this.base_amt == 0){
        point = '0';
       }else{
        if(this.form.activeDetailId == this.makeMoneyList.length - 1){
         point = Math.floor(this.form.makeAmt * 1 / this.base_amt);
       }else{
         point = Math.floor(this.makeMoneyList[this.form.activeDetailId].d * 1 / this.base_amt);
       }
       }
       return point
    }
  }
};
</script>

<style scoped lang="less">
.search-detail {
  border-top: 1px solid #b0b7c6;
  .form-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    grid-auto-rows: 28px;
    border-bottom: 1px solid #b0b7c6;

    .row {
      font-size: 14px;
      display: grid;
      grid-template-columns: 120px 1fr;

      .label {
        text-align: right;
      }
      .value {
        margin-left: 10px;
      }
    }
  }

  .form {
    .row {
      margin: 16px 0;
      display: grid;
      grid-template-columns: 120px 1fr;

      .label {
        width: 120px;
        text-align: right;
        font-size: 14px;
        margin-right: 10px;

        span.red {
          color: #f51f4b;
        }
      }

      .value {
        margin-left: 10px;
        flex-wrap: wrap;
        .item {
          width: 120px;
          height: 56px;
          background: #b3bbcd;
          border-radius: 4px;
          border: 1px solid #aeafc1;
          margin: 4px;
          cursor: pointer;
          .item-top {
            font-size: 18px;
            font-weight: 600;
            span {
              font-size: 13px;
            }
          }
          .item-bottom {
            font-size: 14px;
            color: #545455;
          }

          &.active {
            border-color: #2362d5;
            background: #afc1e3;
            .item-top,
            .item-bottom {
              color: #2362d5;
            }
          }
        }
      }
    }
  }
}

/deep/.el-select__input.is-small {
  width: 284px;
  border: none;
}
</style>
