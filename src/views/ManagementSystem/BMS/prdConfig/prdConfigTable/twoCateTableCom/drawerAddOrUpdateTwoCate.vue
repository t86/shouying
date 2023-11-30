<template>
  <div>
    <!-- 新增或修改二级级分类 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 fs14">
        <div class="coll m-b-2" layout="row" layout-align="start center">
          <div class="label">
            <span>一级分类名称:</span>
          </div>
          <div class="value">{{oneCateInfo.n}}</div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>二级分类名称:</span>
          </div>
          <div class="value">
            <el-input
              v-model="twoCateName"
              size="small"
              @change="limitingRule"
              placeholder="请输入二级分类名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>分类可选要求类型:</span>
          </div>
          <div class="value">
            <el-checkbox
              v-for="(item) in requireList" 
              :key="item.id"
              v-model="item.checked">
              {{item.n}}
            </el-checkbox>
          </div>
        </div>
        <!-- 如果switch开关，添加限制供应时间段的功能，如果设置为true，供应时段（开始-结束）为必填，且支持添加多个 -->
        <div class="coll" layout="column" layout-align="start start">
          <div class="coll" layout="row" layout-align="start start">
            <div class="label">
              <span>开启时间段限制:</span>
            </div>
            <div class="value" layout="column" layout-align="start start">
              <el-switch
                v-model="isTimelimit"
              ></el-switch>
              <span class="color-red m-t-2">说明：开关关闭则表示全部时段都可以供应，开启后需配置供应时间段</span>
            </div>
          </div>
          <div class="coll" layout="column" layout-align="start center" v-if="isTimelimit">
            <div class="coll" style="width: 100%;" layout="row" layout-align="start center" >
              <div class="label">
                <span>供应时段:</span>
              </div>
            </div>
            <div class="value" layout="column" layout-align="start center">
              <div class="coll" layout="row" layout-align="start center">
                <span class="color-red" style="width: 70px;">（必填）</span>
                <el-time-picker
                  v-model="period1.start"
                  style="width:220px; height:36px"
                  placeholder="开始时段"
                  format="HH:mm"
                  value-format="HH:mm"
                ></el-time-picker>
              <!-- 画一条水平垂直居中，颜色为黑色，宽度20px的线 -->
              <div style="width: 20px; height: 0.5px; background-color: #000; margin: 0 10px;"></div>
                <el-time-picker
                  v-model="period1.end"
                  style="width:220px; height:36px"
                  placeholder="结束时段"
                  format="HH:mm"
                  value-format="HH:mm"
                ></el-time-picker>
              </div>
              <div class="coll" layout="row" layout-align="start center">
              <span class="color-red" style="width: 70px;"></span>
              <el-time-picker
                v-model="period2.start"
                style="width:220px; height:36px"
                placeholder="开始时段"
                format="HH:mm"
                value-format="HH:mm"
              ></el-time-picker>
              <!-- 画一条水平垂直居中，颜色为黑色，宽度20px的线 -->
              <div style="width: 20px; height: 0.5px; background-color: #000; margin: 0 10px;"></div>
              <el-time-picker
                v-model="period2.end"
                style="width:220px; height:36px"
                placeholder="结束时段"
                format="HH:mm"
                value-format="HH:mm"
              ></el-time-picker>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
<script>
export default {
  data() {
    return {
      oneCateInfo: {},
      twoCateName: "",
      requireList: [],
      isTimelimit: false,
      period1: {
        start: '',
        end: ''
      },
      period2: {
        start: '',
        end: ''
      },
    };
  },
  methods: {
    // Function to add a new time period
    addTimePeriod() {
      this.timePeriods.push({ start: "", end: "" });
    },
    // Function to remove a time period at a specific index
    removeTimePeriod(index) {
      this.timePeriods.splice(index, 1);
    },
    // 获取编辑前信息
    async getDetail(){
      const params = {
        id: this.currentInfo.id * 1
      }
      try {
        const res = await this.$api.BMS.tcate.requesttcateget(params)
        if(res.code == 1) {
          this.twoCateName = res.data.two_cate_info.name
          this.oneCateInfo = {
            n: res.data.two_cate_info.one_cate_name,
            id: res.data.two_cate_info.one_cate_id
          }
          this.requireList = (res.data.rqm_types || []).map(item => ({
            ...item,
            checked: res.data.two_cate_info.rqm_types && res.data.two_cate_info.rqm_types.includes(item.id)
          }))
          this.isTimelimit = res.data.two_cate_info.enable_time_limit == 1 ? true : false,
          this.period1 = {
            start: res.data.two_cate_info.begin_time,
            end: res.data.two_cate_info.end_time
          }
          this.period2 = {
            start: res.data.two_cate_info.begin_time2,
            end: res.data.two_cate_info.end_time2
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },
    // 获取要求类型列表
    async getRequireList(){
      try {
        const res = await this.$api.BMS.require.requestRqmTypelist()
        if(res.code == 1) {
          this.requireList = (res.data || []).map(item => ({
            ...item,
            checked: false
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    limitingRule(){
      if (this.twoCateName == '') {
        this.$message.warning('请输入二级分类名称')
      } else if (this.$overall.character(this.twoCateName) > 16) {
        this.$message.warning('输入文字长度超过8')
      }
    },

    async onSubmit() {

      // 判断period1的开始时间和结束时间不能和period2的开始时间和结束时间有重合，同时每个开始时间都必须小于结束时间
      if(this.period1.start > this.period1.end || this.period2.start > this.period2.end) {
        return this.$message.warning('开始时间不能大于结束时间')
      }
      if(this.period1.start > this.period2.start && this.period1.start < this.period2.end) {
        return this.$message.warning('两个时间段不能有重合')
      }
      if(this.period1.end > this.period2.start && this.period1.end < this.period2.end) {
        return this.$message.warning('两个时间段不能有重合')
      }

      if (this.twoCateName.length <= 0)
        return this.$message.warning("请输入二级分类名称");
      const params = {
        name: this.twoCateName || '',
        rqm_types: this.requireList.filter(item => item.checked).map(item => item.id * 1),
        ...this.type == 1 && {one_cate_id: this.oneCateInfo.id},
        ...this.type == 2 && {id : this.currentInfo.id},
        enable_time_limit: this.isTimelimit ? 1 : 2,
        ...this.isTimelimit && 
            {
              begin_time: this.period1.start,
              end_time: this.period1.end,
              ...this.period2.start && {
                begin_time2: this.period2.start,
                end_time2: this.period2.end
              },
              
            },
      };
      try {
        const api = this.type == 1 ? 'requesttcatenew' : 'requesttcatesave'
        const res = await this.$api.BMS.tcate[api](params)
        if(res.code == 1) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.success('操作成功')
        } else if (res.code == 6) {
          this.onCancelDrawer()
          this.$emit('getTableData', true)
          this.$emit('getMenuList')
          this.$message.warning("创建成功，状态无效，" + res.msg)
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('新增失败', error);
      }
    },
    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    type: {
      default: 1
    },
    menuList: {
      default: () => ([])
    },
    currentInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.type == 1 ? "新增二级分类" : "编辑二级分类";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if (this.type == 1) {
            this.twoCateName = "";
            const oneCateInfo = this.menuList.find(item => item.id == this.$route.query.menuId)
            this.oneCateInfo = oneCateInfo || {}
            this.getRequireList()
          } else {
            this.getDetail()
          }
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
</style>
<style lang="less" scoped>
.coll {
  margin-bottom: 20px;
  .label {
    width: 150px;
  }
}


</style>