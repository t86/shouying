<template>
  <el-drawer :title="type === 1 ? '新增套餐模板' : '编辑套餐模板'" :visible.sync="drawerVisible" :direction="direction"
    :before-close="handleClose" size="85%">
    <el-form :model="form" :rules="rules" ref="form" label-width="160px" class="w-5/6">
      <el-form-item label="模板名称" prop="name" required>
        <el-input v-model="form.name" placeholder="请输入模板名称"></el-input>
      </el-form-item>
      <el-form-item label="明细规则(N选M)" prop="count" required>
        <div class="flex">
          <span class="w-10">
            {{ selectedPrds.length }}选
          </span>
          <el-input type="number" v-model="form.count" placeholder="输入数量"></el-input>
        </div>
      </el-form-item>
      <el-form-item label="可选组单品" required>
        <el-button type="primary" size="medium" @click="clickNewPrd"> 新增</el-button>
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">名称</div>
                <div class="th">分类</div>
                <div class="th">单价</div>
                <div class="th">数量</div>
                <div class="th">存货商品名</div>
                <div class="th">类型</div>
                <div class="th">营业类型</div>
                <div class="th">状态</div>
                <div class="th">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" v-for="(item, index) in selectedPrds" :key="index" layout="row"
                layout-align="space-between center">
                <div class="td">{{ index + 1 }}</div>
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.on }} > {{ item.tn }}</div>
                <div class="td">{{ item.p }}</div>
                <div class="td">
                  <el-input type="number" v-model="item.c"></el-input>
                </div>
                <div class="td">{{ item.mn }}</div>
                <div class="td">{{ item.pt }}</div>
                <div class="td">{{ item.bt }}</div>
                <div class="td">{{ type === 1 ? (item.s === 1 ? '有效' : '无效') : item.s }}</div>
                <div class="td">
                  <el-button type="text" @click="deletePrd(item)">删除</el-button>
                </div>
              </div>
              <div class="no-data" v-if="selectedPrds.length == 0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </el-form-item>
    </el-form>
    <div class="drawer-footer">
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" @click="submitForm">确定</el-button>
    </div>
    <drawerAddPrd v-model="showAddPrdDrawer" :checkedPrdList="selectedPrds" @selectedPrds="submitSelectedPrds" />

  </el-drawer>
</template>

<script>
import drawerAddPrd from "./drawerAddPrdNew"
export default {
  name: "DrawerAddTaocanTemplate",
  props: {
    type: {
      type: Number,
      required: true,
    },
    currentInfo: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      showAddPrdDrawer: false,
      drawerVisible: true,
      direction: "rtl",
      selectedPrds: [],
      form: {
        name: "",
        count: null,
      },
      rules: {
        name: [
          { required: true, message: "请输入模板名称", trigger: "blur" }
        ],
        count: [
          { required: true, message: "请输入数量", trigger: "blur" }
        ],

      },
    };
  },
  methods: {
    deletePrd(prd) {
      this.selectedPrds = this.selectedPrds.filter(item => item.id != prd.id)
    },
    submitSelectedPrds(prds) {
      console.log("submitSelectedPrds", prds)
      this.selectedPrds = prds
    },
    clickNewPrd() {
      this.showAddPrdDrawer = true
    },
    handleClose() {
      this.$emit("closeDrawer");
    },
    submitForm() {
      this.$refs.form.validate((valid) => {
        if (valid) {
          // 这里添加提交表单的逻辑
          console.log("表单提交", this.form);
          this.$confirm('确认调整模板内容?调整后使用该模板的套餐也会一起调整!', '确认', {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }).then(async () => {
            let params = {
              name: this.form.name,
              sel_cnt: this.form.count * 1,
              prd_ids: this.selectedPrds.map(item => item.id),
              prd_cnts: this.selectedPrds.map(item => item.c * 1),
            }
            if (this.type === 2) {
              params.id = this.currentInfo.id
            }
            const res = this.type === 1 ? await this.$api.BMS.Prd.new_prd_set_tpl(params) : await this.$api.BMS.Prd.save_prd_set_tpl(params)
            res.code == 1 ? this.$message.success("创建成功") : this.$message.warning(res.msg);
            this.handleClose();
          }).catch(() => {
            this.handleClose();
          });
        } else {
          console.log("表单验证失败");
          return false;
        }
      });
    },
  },
  async created() {
    if (this.type === 2 && this.currentInfo) {
      let res = await this.$api.BMS.Prd.get_prd_set_tpl({ id: this.currentInfo.id })
      console.log(res)
      if (res.code === 1) {
        this.form.name = res.data.name
        this.form.count = res.data.sel_cnt
        this.selectedPrds = res.data.dtls

      } else {
        this.$message.warning(res.msg);
      }
      // this.form = { ...this.currentInfo };
    }
  },
  components: {
    drawerAddPrd
  },
};
</script>

<style scoped lang="less">
@import "../style/erp/form.less";
@import "../style/erp/table.less";
</style>

<style lang="less" scoped>
.drawer-footer {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 20px;
  text-align: center;
  background-color: #fff;
}
</style>
