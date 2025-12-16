<template>
  <div class="search-detail p-t-4">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号:</div>
        <div class="value">{{ vipInfo.card_no || '暂无' }}</div>
      </div>
      <div class="row">
        <div class="label">会员卡等级:</div>
        <div class="value">{{ vipInfo.card_level_name }}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机:</div>
        <div class="value">{{ vipInfo.bind_phone || '暂无' }}</div>
      </div>
      <div class="row">
        <div class="label">联系手机:</div>
        <div class="value">{{ vipInfo.contact_phone || '暂无' }}</div>
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
      <div class="row">
        <div class="label">注册推荐人:</div>
        <div class="value">{{ getRegisterRecommenderName() }}</div>
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
        <div class="value" layout="row" layout-align="start center">
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
          <el-button
            class="m-l-2"
            size="small"
            type="text"
            @click="clearRecommender"
            v-if="form.personVal"
          >
            清除
          </el-button>
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
    
    // 获取注册推荐人姓名
    getRegisterRecommenderName() {
      // 优先使用新接口返回的充值推荐人信息
      if (this.vipInfo.deposit_sales_emp_name) {
        return this.vipInfo.deposit_sales_emp_name;
      }
      
      // 兼容原有逻辑
      if (!this.vipInfo.sales_emp_id || !this.personOptions.length) {
        return '暂无';
      }
      
      const recommender = this.personOptions.find(person => 
        person.id === this.vipInfo.sales_emp_id
      );
      
      return recommender ? `${recommender.name} (${recommender.code})` : '暂无';
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
          console.log("会员卡号:", this.vipInfo.card_no);
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
          
          // 🔍 调试信息：检查积分相关数据
          console.log("🎯 [积分调试] 获取充值前会员卡信息成功");
          console.log("📋 [积分调试] 接口返回的完整数据:", res.data);
          console.log("📋 [积分调试] 积分基数 (base_amt):", res.data.base_amt, typeof res.data.base_amt);
          console.log("📋 [积分调试] 充值规则 (deposit_rules):", this.depositRules);
          console.log("📋 [积分调试] 充值渠道列表:", this.typeOption);
          console.log("📋 [积分调试] 当前设置的 base_amt:", this.base_amt);
          
          // 检查充值规则中的积分配置
          if (this.depositRules && this.depositRules.length > 0) {
            this.depositRules.forEach((rule, index) => {
              console.log(`📋 [积分调试] 规则 ${index}:`, rule);
              if (rule.p !== undefined) {
                console.log(`  - 规则 ${index} 积分配置 (p):`, rule.p, typeof rule.p);
              }
            });
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取充值前会员卡信息失败", error);
      }
    },
    
    // 清除本次充值的推荐人
    clearRecommender() {
      this.form.personVal = "";
    },

    // 按照五层规则设置推荐人
    async setRecommenderByRules(cardId, openCardSalesEmpId) {
      try {
        console.log("🎯 [推荐人设置] 开始按规则设置推荐人");
        console.log("  - 卡ID:", cardId);
        console.log("  - 开卡推荐人ID:", openCardSalesEmpId);
        console.log("  - 默认推荐人ID (卡台订位人):", this.defaultRecommender);
        console.log("  - 来源路由 (sourceRoute):", this.sourceRoute);
        console.log("  - 当前卡台信息:", this.$store.state.orderInfo && this.$store.state.orderInfo.currentCardInfo);
        
        // 第零层：如果是从收银卡台进入（orderCard 或 orderMealList），直接使用卡台的订位人
        if (this.sourceRoute === 'moneyCard' || this.sourceRoute === 'payOrder') {
          const currentCardSalesEmpId = this.$store.state.orderInfo && 
                                        this.$store.state.orderInfo.currentCardInfo && 
                                        this.$store.state.orderInfo.currentCardInfo.salesEmpId;
          if (currentCardSalesEmpId) {
            console.log("🎯 [第零层] 从收银卡台进入，使用卡台订位人ID:", currentCardSalesEmpId);
            
            const matchedPerson = this.findPersonInOptions(currentCardSalesEmpId);
            if (matchedPerson) {
              this.form.personVal = matchedPerson.id;
              console.log("✅ [第零层] 设置卡台订位人为默认值:", this.form.personVal, matchedPerson.name);
              return;
            } else {
              console.log("⚠️ [第零层] 卡台订位人不在当前推荐人列表中");
            }
          } else {
            console.log("⚠️ [第零层] 卡台没有订位人信息");
          }
        } else {
          console.log("⚠️ [第零层] 不是从收银卡台进入，跳过第零层逻辑");
        }
        
        // 第一层：查询该卡上次充值时的充值推荐人
        const params = {
          card_id: cardId
        };
        const res = await api_vip.reqGetCustCardLastSales(params);
        console.log("✅ [第一层] 上次充值推荐人接口返回:", res);
        
        if (res.code == 1 && res.data && res.data.id) {
          const lastRechargeSalesEmpId = res.data.id;
          console.log("✅ [第一层] 找到上次充值推荐人ID:", lastRechargeSalesEmpId, "姓名:", res.data.name);
          
          // 尝试在推荐人列表中找到匹配的推荐人
          const matchedPerson = this.findPersonInOptions(lastRechargeSalesEmpId);
          if (matchedPerson) {
            this.form.personVal = matchedPerson.id;
            console.log("✅ [第一层] 设置上次充值推荐人为默认值:", this.form.personVal, matchedPerson.name);
            return;
          } else {
            console.log("⚠️ [第一层] 上次充值推荐人不在当前推荐人列表中");
          }
        } else {
          console.log("⚠️ [第一层] 没有找到上次充值推荐人");
        }
        
        // 第二层：如果没有上次充值推荐人，则使用开卡推荐人
        if (openCardSalesEmpId) {
          console.log("🔍 [第二层] 尝试使用开卡推荐人ID:", openCardSalesEmpId);
          const matchedPerson = this.findPersonInOptions(openCardSalesEmpId);
          if (matchedPerson) {
            this.form.personVal = matchedPerson.id;
            console.log("✅ [第二层] 设置开卡推荐人为默认值:", this.form.personVal, matchedPerson.name);
            return;
          } else {
            console.log("⚠️ [第二层] 开卡推荐人不在当前推荐人列表中");
          }
        } else {
          console.log("⚠️ [第二层] 没有开卡推荐人信息");
        }
        
        // 第三层：使用卡台订位人（从props传入的defaultRecommender）
        if (this.defaultRecommender && this.defaultRecommender > 0) {
          console.log("🔍 [第三层] 尝试使用卡台订位人ID:", this.defaultRecommender);
          const matchedPerson = this.findPersonInOptions(this.defaultRecommender);
          if (matchedPerson) {
            this.form.personVal = matchedPerson.id;
            console.log("✅ [第三层] 设置卡台订位人为默认值:", this.form.personVal, matchedPerson.name);
            return;
          } else {
            console.log("⚠️ [第三层] 卡台订位人不在当前推荐人列表中");
          }
        } else {
          console.log("⚠️ [第三层] 没有卡台订位人信息");
        }
        
        // 第四层：如果前三层都没有，则推荐人为空白
        console.log("⚠️ [第四层] 推荐人设置为空白，允许用户手动选择");
        this.form.personVal = "";
        
      } catch (error) {
        console.error("❌ [推荐人设置] 设置推荐人失败:", error);
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
    defaultRecommender: {
      type: Number,
      default: 0 // 默认推荐人ID（卡台订位人）
    },
    sourceRoute: {
      type: String,
      default: '' // 来源路由：orderCard (点单页面), orderMealList (点餐列表), 空字符串表示直接从会员管理页面
    }
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
       
       console.log("🎯 [积分计算] 开始计算赠送积分");
       console.log("📋 [积分计算] 当前选择的充值详情ID:", this.form.activeDetailId);
       console.log("📋 [积分计算] 充值列表:", this.makeMoneyList);
       
       // 检查是否是自定义模式（最后一个选项）
       if(this.form.activeDetailId == this.makeMoneyList.length - 1){
         // 自定义模式：基于 base_amt 计算积分
         if(this.base_amt == 0){
           point = '0';
           console.log("📋 [积分计算] 自定义模式 - base_amt 为 0，不赠送积分");
         } else {
           const makeAmt = this.form.makeAmt * 1;
           point = Math.floor(makeAmt / this.base_amt);
           console.log("📋 [积分计算] 自定义模式 - 充值金额:", makeAmt, "积分基数:", this.base_amt, "计算积分:", point);
         }
       } else {
         // 规则模式：直接使用规则中的 p 字段
         const currentRule = this.makeMoneyList[this.form.activeDetailId];
         if (currentRule && currentRule.p !== undefined) {
           point = currentRule.p;
           console.log("📋 [积分计算] 规则模式 - 直接使用规则积分 (p):", point);
         } else {
           point = '0';
           console.log("📋 [积分计算] 规则模式 - 规则中没有积分配置，不赠送积分");
         }
       }
       
       console.log("📋 [积分计算] 最终积分结果:", point);
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
    grid-template-columns: repeat(2, 1fr); // 🎯 两列布局
    gap: 8px 20px; // 行间距8px，列间距20px
    border-bottom: 1px solid #b0b7c6;
    padding-bottom: 15px;
    margin-bottom: 20px;
    
    // 小屏幕适配 - 改为单列
    @media (max-width: 900px) {
      grid-template-columns: 1fr; // 单列
      padding-bottom: 12px;
      margin-bottom: 15px;
      gap: 6px;
    }
    
    // iPad 竖屏适配 - 改为单列
    @media (orientation: portrait) {
      grid-template-columns: 1fr; // 单列
      padding-bottom: 10px;
      margin-bottom: 12px;
      gap: 6px;
    }

    .row {
      font-size: 14px;
      display: flex;
      width: 100%;
      min-height: 32px;
      align-items: center;

      .label {
        width: 110px;
        min-width: 110px;
        text-align: left;
        color: #666;
        padding-right: 8px;
        font-size: 14px;
      }
      .value {
        flex: 1;
        color: #333;
        font-weight: 500;
        font-size: 14px;
        word-break: break-all; // 防止长文本溢出
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

/* 充值规则说明样式 */
.recharge-rules-section {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 25px;
  border: 1px solid #e9ecef;
  
  .section-title {
    font-size: 16px;
    font-weight: 600;
    color: #333;
    margin-bottom: 15px;
    
    span {
      display: flex;
      align-items: center;
      gap: 8px;
    }
  }
  
  .rules-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 15px;
    
    .rule-item {
      background: white;
      border-radius: 6px;
      padding: 15px;
      border: 1px solid #dee2e6;
      transition: all 0.2s ease;
      
      &:hover {
        border-color: #409eff;
        box-shadow: 0 2px 8px rgba(64, 158, 255, 0.1);
      }
      
      .rule-amount {
        font-size: 16px;
        font-weight: 600;
        color: #409eff;
        margin-bottom: 8px;
      }
      
      .rule-benefits {
        display: flex;
        flex-direction: column;
        gap: 4px;
        
        .benefit-item {
          font-size: 14px;
          color: #666;
          display: flex;
          align-items: center;
          gap: 6px;
        }
      }
    }
  }
  
  @media (max-width: 900px) {
    .rules-grid {
      grid-template-columns: 1fr;
    }
  }
  
  @media (orientation: portrait) {
    padding: 15px;
    
    .rules-grid {
      grid-template-columns: 1fr;
      gap: 12px;
      
      .rule-item {
        padding: 12px;
      }
    }
  }
}

/deep/.el-select__input.is-small {
  width: 284px;
  border: none;
}
</style>
