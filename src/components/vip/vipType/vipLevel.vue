<template>
  <div>
    <div class="session add-update-vip-type">
      <!-- 新增卡类型 -->
      <template >
        <div class="top-info" v-if="status==1">
          <label for="autoUpgrade">卡等级自动升级:</label>
          <input type="checkbox" id="autoUpgrade" v-model="autoUpgradeEnabled">
          <div style="padding-left:30px; font-size: 14px;color: gray; margin: 10px 5px;">开关开启后需配置每个等级的等级经验门槛值，达到后，客人端将自动升级</div>
        </div>

        <div class="bottom-info">
          <p>
            <span class="bold m-r-2">卡等级信息</span>
            <span>不同的等级可享受的权益不同</span>
          </p>
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th"></div>
                <div class="th">等级名称</div>
                <div class="th">等级封面</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in cardInfoList" :key="item.id">
                <div class="td" layout="row" layout-align="space-between center">
                  <img v-if="index==0" @click="addVipDeepItem" :src="require('@/assets/vip-imgs/add.png')" alt />
                  <img v-else @click="deleteVipDeepItem(item)" :src="require('@/assets/vip-imgs/del.png')" alt />
                  <span class="default" v-if="index==0">默认等级</span>
                </div>
                <div class="td" layout="row" layout-align="start center">
                  <el-input v-model="item.name" :disabled="item.disabled" size="mini" style="width:calc(100% - 100px);max-width:300px;border-radius:4px" :style="{background:item.disabled?'rgba(138,149,176,0.3)':'#DDE0E9'}" placeholder="请输入等级名称"></el-input>
                  <button v-if="item.id && !item.disabled" class="btn mini primary m-l-2" @click="saveDeepNameHandle(item)">保存</button>
                  <button v-if="item.id && item.disabled" class="btn mini info m-l-2" @click="item.disabled=false">编辑</button>
                </div>
                <div class="td" layout="row" layout-align="start center">
                  <img :src="imgBaseUrl + item.bgiName " alt="">
                  <button class="btn mini info m-l-2" @click="updateBgiImgHandle(item)">更改</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>
      <!-- 新增卡等级 -->
      <template v-if="status==2">
        <div class="top-info add-deep">
          <div class="form" style="border:none">
              <div class="row" v-if="subStatus==1 || subStatus==3" layout="row" layout-align="start center">
              <div class="label">
                <span class="red">*</span>
                <span>会员卡等级:</span>
              </div>
              <el-input
                v-model="formDeep.deepName"
                size="small"
                placeholder="请输入会员卡等级(1-10字)"
                style="width:284px;"
              ></el-input>
            </div>
              <div class="row" layout="row" layout-align="start start">
              <div class="label">
                <span class="red">*</span>
                <span>选择封面:</span>
              </div>
              <div class="upload">
                <!-- 默认封面 -->
                <div class="default">
                  <p class="title">默认封面</p>
                  <div class="default-img" layout="row" layout-align="start center">
                    <div class="item-bgi" v-for="(item, index) in defaultBgiImgList" :key="item.uid" @click="activeBgiUid=item.uid">
                      <div class="top" :class="{'active': item.uid == activeBgiUid}">
                        <div class="top-content">
                          <img class="bgi" :src="imgBaseUrl + item.url" alt="">
                        </div>
                        <img class="ok" v-if="item.uid == activeBgiUid" :src="require('@/assets/vip-imgs/bgi-checked.png')" alt="" >
                      </div>
                      <p class="bgi-name">封面{{index+1}}</p>
                    </div>
                  </div>
                </div>
                <!-- 自定义封面 -->
                <div class="default self m-t-6">
                  <p class="title">
                    <span>自定义封面</span>
                    <span class="bgi-tips">点击上传图片，仅支持：jpg、png的格式</span>
                  </p>
                  <div class="default-img" layout="row" layout-align="start center">
                    <!-- 上传图片图标 -->
                    <div class="upload item-bgi" >
                      <div class="top">
                        <div class="top-content" layout="column" layout-align="center center" @click="$refs.uploadRef.click()">
                          <img class="upload-icon" :src="require(`@/assets/vip-imgs/bgi-add.png`)" alt="">
                          <p class="upload-p">点击上传</p>
                        </div>
                      </div>
                      <input ref="uploadRef" type="file" accept="image/png,image/jpg" v-show="false" @change="uploadRequest" />
                      <p class="bgi-name">封面</p>
                    </div>
                    <div class="item-bgi" v-for="(item, index) in uploadBgiImgList" :key="item.uid"  @click="activeBgiUid=item.uid">
                      <div class="top" :class="{'active': item.uid == activeBgiUid}">
                        <div class="top-content">
                          <img class="bgi" :src="imgBaseUrl + item.url" alt="">
                        </div>
                        <img class="ok" v-if="item.uid==activeBgiUid" :src="require('@/assets/vip-imgs/bgi-checked.png')" alt="" >
                        <img class="del" :src="require('@/assets/vip-imgs/del.png')" alt="" @click="deleteBgiItemHandle(item)" >
                      </div>
                      <p class="bgi-name">自定义封面{{index+1}}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="form-btn" layout="row" layout-align="center center">
            <el-button type="info" @click="onCancelDrawer($event, false)">关闭</el-button>
            <el-button v-if="!(item.id && subStatus == 1)" type="primary" @click="onSubmit">确定</el-button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
 
<script>
import api_vip from '@/api/vip'
let imgBaseUrl = "";
export default {
  data() {
    return {
      show: false,
      imgBaseUrl,
      autoUpgradeEnabled: false,
      status: 1,  // 1：新增卡类型  2：新增等级
      subStatus: 1,  // 1:新增等级  2：修改等级背景图片 3:编辑状态新增等级
      form: {
        vipName: "",
        isDefault: this.canDisabledDefault ? true : false
      },
      formDeep:{
        deepName: ''
      },
      currentDeepInfo: {}, // 当前修改的卡等级
      cardInfoList: [
        {
          id: +new Date(),
          name: "默认等级",
          disabled: false,
          bgiName: "default1.png"
        }
      ],
      // 默认选中的背景图uid
      activeBgiUid: '',
      // 默认背景图
      defaultBgiImgList: [],
      // 自己上传的背景图片列表
      uploadBgiImgList: []
    };
  },
  methods: {
    /*
      卡类型相关
     */
    // 获取待编辑的类型信息
    async getEditInfoHandle(){
      const params = {
        id: this.item.id * 1 //  int64   会员卡类型Id
      }
      try {
        const res = await api_vip.reqGetVipTypeDetail(params)
        if (res.code == 1) {
          this.form.vipName = res.data.name
          this.form.isDefault = res.data.is_def == 1
          this.imgBaseUrl = res.data.pic_url_prefix || imgBaseUrl
          const cardInfoList = (res.data.card_levels || []).map(item => ({
            id: item.id,
            d: item.d,
            name: item.n,
            disabled: true,
            bgiName: item.p
          }))
          cardInfoList.length == 0 ? '' : this.cardInfoList = [...cardInfoList]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取待编辑的卡类型信息失败', error)
      }
    },
    // 添加卡等级
    addVipDeepItem(){
      this.currentDeepInfo = {}
      this.changeStatus(2)
    },
    // 删除卡等级
    async deleteVipDeepItem(itemInfo){
      if (this.item.id) {
        // 编辑状态删除会员卡等级
        const result = await this.deleteEditStatusVipDeepItem(itemInfo.id)
        if (!result) return
      }
      const cardInfoList = [...this.cardInfoList]
      const index = cardInfoList.findIndex(item => item.id == itemInfo.id)
      if (index > -1) {
        cardInfoList.splice(index, 1)
        this.cardInfoList = [...cardInfoList]
      }
    },
    // 删除会员卡等级
    async deleteEditStatusVipDeepItem(id) {
      const params = {
        id: id * 1 //   int64   卡等级Id
      }
      try {
        const res = await api_vip.reqDelVipDeep(params)
        if (res.code == 1) {
          return true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除会员卡等级失败', error)
      }
    },
    // 修改会员卡类型名称
    async updateVipNameHandle(){
      if (!this.item.id) return
      if (!this.form.vipName) return this.$message.warning('请输入会员卡类型')
      const params = {
        id: this.item.id * 1,  //    int64 卡类型Id
        name: this.form.vipName,  //  string   卡类型名称
      }
      try {
        const res = await api_vip.reqUpdateVipType(params)
        if (res.code == 1) {
          this.$message.success('修改会员卡类型成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('编辑会员卡类型名称失败', error)
      }
    },
    // 修改会员卡类型默认项
    async updateVipDefaultHandle(){
      if (!this.item.id) return
      const params = {
        id: this.item.id * 1,  //    int64 卡类型Id
      }
      try {
        const res = await api_vip.reqUpdateDefaultVipType(params)
        if (res.code == 1) {
          this.$message.success('修改会员卡类型成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('编辑会员卡类型名称失败', error)
      }
    },
    // 保存等级名称
    async saveDeepNameHandle(itemInfo) {
      const params = {
        id : itemInfo.id * 1,  //  int64    卡等级Id
        name : itemInfo.name,  // string   卡等级名称
      }
      try {
        const res = await api_vip.reqUpdateVipDeepName(params)
        if (res.code == 1) {
          this.$message.success('保存成功')
          itemInfo.disabled = true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('会员卡等级名称修改失败', error)
      }
    },
    // 更改等级封面图片
    updateBgiImgHandle(itemInfo){
      this.currentDeepInfo = {...itemInfo}
      this.changeStatus(2)
      this.changeSubStatus(2)
    },
    /*
      背景图片相关
     */
    // 获取自定义背景封面
    async getUploadedBgiImg(){
      try {
        const res = await api_vip.reqGetUploadBgiImg()
        if (res.code == 1) {
          this.uploadBgiImgList = (res.data.records || []).map(item => ({
            uid: item.id,
            name: item.pic_name,
            url: res.data.pic_url_prefix + item.pic_name
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('自定义封面背景获取失败', error)
      }
    },
    // 上传自定义封面背景图片
    uploadRequest(e) {
      let file =  e.path[0].files[0]
      this.$api.BMS.Prd.requestOssPt().then(item => {
        let res = item.data,
          imgName =
            this.$overall.generateUUID() + "." + file.name.split(".")[1],
          key = res.dir + imgName;
        this.$api.BMS.Prd.handleUploadFile(
          res.host,
          {
            key: key,
            policy: res.policy,
            OSSAccessKeyId: res.accessid,
            success_action_status: "200", //让服务端返回200,不然，默认会返回204
            signature: res.signature
          },
          file
        ).then(() => {
          this.addUploadBgiImgToServer(imgName)
        });
      });
    },
    // 发送自定义封面背景至服务器
    async addUploadBgiImgToServer(picName){
      const params = {
        pic_name: picName  //   string  卡面图片名称,去掉url前缀后的名称
      }
      try {
        const res = await api_vip.reqAddUploadBgiImg(params)
        if (res.code == 1) {
          this.uploadBgiImgList = [...this.uploadBgiImgList, {
            uid: res.data.id,
            name: picName,
            url: this.imgBaseUrl + picName
          }]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('添加自定义封面失败', error)
      }
    },
    // 删除自定义封面背景图片
    async deleteBgiItemHandle(itemInfo){
      const params = {
        id: itemInfo.uid * 1  //   int64  自定义卡面配置Id
      }
      try {
        const res = await api_vip.reqDelUploadBgiImg(params)
        if (res.code == 1) {
          const uploadBgiImgList = [...this.uploadBgiImgList]
          const index = uploadBgiImgList.findIndex(item => item.uid == itemInfo.uid)
          if(index > -1) {
            uploadBgiImgList.splice(index, 1)
            this.uploadBgiImgList = [...uploadBgiImgList]
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除自定义封面图片失败', error)
      }
      
    },

    // 编辑状态更改封面背景图
    async updateItemBgiImg(picName) {
      const params = {
        id: this.currentDeepInfo.id,   //      int64    卡等级Id
        pic_name: picName,   //   string    卡等级卡面
      }
      try {
        const res = await api_vip.reqUpdateVipDeepPic(params)
        if (res.code == 1) {
          return true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('编辑等级封面图失败', error)
      }
    },

    // 编辑状态添加会员等级
    async addVipDeep(deepName, bgiName){
      const params = {
        id: this.item.id * 1,  //    int64    卡类型Id
        level_name: deepName,  // string   卡等级名称
        level_pic_name: bgiName,  // string   卡等级卡面图片
        exp_threshold: 0, // int64 等级经验阀值(当开启自动升级的时候, 需要配置, 否则=0)
      }

      try {
        const res = await api_vip.reqAddVipTypeDeep(params)
        if (res.code == 1) {
          return res.data.id
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('编辑状态添加卡等级失败', error)
      }
    },

    // 获取会员卡背景图
    async getImgBaseUrl(){
      try {
        const res = await api_vip.reqOssImgBaseUrl()
        if(res.code == 1) {
          return res.data.p || ''
        }
      } catch (error) {
        console.log('获取背景图baseUrl失败', error);
      }
    },

    // 获取默认封面背景图
    getDefaultBgiImg(){
      const defaultBgiImgList = []
      for (var i = 0; i < 6; i++) {
         defaultBgiImgList.push({
            uid: +new Date() + i,
            name: 'default' + (i + 1) + '.png',
            url: imgBaseUrl + 'default' + (i + 1) + '.png'
         })
      };
      this.defaultBgiImgList = [...defaultBgiImgList]
    },

    /*
      其它
     */
    // 修改状态
    async changeStatus(status=1){
      this.subStatus = this.item.id ? 3 : 1
      if (status == 2) {
        this.getDefaultBgiImg()
        await this.getUploadedBgiImg()
        if(!this.item.id) {
          this.activeBgiUid = ''
          this.formDeep.deepName = ''
        } else {
          if(this.currentDeepInfo.id){
            // 编辑
            const isDefaultBgi = this.defaultBgiImgList.find(item => item.name == this.currentDeepInfo.bgiName)
            if (isDefaultBgi) {
              this.activeBgiUid = isDefaultBgi.uid
            } else {
              const selfBgi = this.uploadBgiImgList.find(item => item.name == this.currentDeepInfo.bgiName)
              this.activeBgiUid = selfBgi.id
            }
          } else {
            // 新增
            this.activeBgiUid = ''
          }
        }
      }
      this.status = status
    },
    changeSubStatus(subStatus=1){
      this.subStatus = subStatus
    },
    // 提交
    async onSubmit(){
      if(this.status == 1){
        // 新建会员卡类型
        if(!this.form.vipName) return this.$message.warning('请输入卡类型名称')
        const params = {
          name: this.form.vipName, // string  卡类型名称
          is_def: this.form.isDefault ? 1 : 2, //   int   是否默认 1 默认 2 不默认
          // level_names: this.cardInfoList.map(item => item.name),  // []string    卡等级名称列表
          // level_pic_names: this.cardInfoList.map(item => item.bgiName),  // []string   卡面图片列表
        }
        try {
          const res = await api_vip.reqAddVipType(params)
          if (res.code == 1) {
            this.$message.success('新建成功')
            this.onCancelDrawer()
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('新增会员卡等级失败', error)
        }
      } else if(this.status == 2) {
        // 会员卡等级
        if(!this.formDeep.deepName && this.subStatus == 1) return this.$message.warning('请输入会员卡等级')
        if(!this.activeBgiUid) return this.$message.warning('请选择会员卡背景图')
        const bgiInfo = this.defaultBgiImgList.find(item => item.uid == this.activeBgiUid) || this.uploadBgiImgList.find(item => item.uid == this.activeBgiUid)
        if(this.subStatus == 1 || this.subStatus == 3) {
          // 新建卡等级
          let id = +new Date()
          if (this.item.id) {
            const result = await this.addVipDeep(this.formDeep.deepName, bgiInfo.name)
            id = result || id
            if (!result) return
          }
          this.cardInfoList = [...this.cardInfoList, {
            id,
            name: this.formDeep.deepName,
            disabled: true,
            bgiName: bgiInfo.name,
          }]
        } else if (this.subStatus == 2) {
          // 修改等级封面
          if(this.item.id) {
            // 编辑
            const result = await this.updateItemBgiImg(bgiInfo.name)
            if (!result) return 
          }
          const cardInfoList = [...this.cardInfoList]
          cardInfoList.forEach(el => {
            if(el.id == this.currentDeepInfo.id) {
              el.bgiName = bgiInfo.name
            }
          })
          this.cardInfoList = [...cardInfoList]
        }
        this.currentDeepInfo = {}
        this.changeStatus(1)
        this.changeSubStatus(1)
      }
    },
    onCancelDrawer(e, type) {
      if(this.status > 1 && !type) {
        return this.changeStatus(this.status - 1)
      }
      this.$emit("showOrHideHandle");
    },

    async resetData(){
      this.status = 1
      this.subStatus = 1
      this.imgBaseUrl = await this.getImgBaseUrl()
      this.form = {
        vipName: "",
        isDefault: this.canDisabledDefault ? true : false
      }
      this.formDeep = {
        deepName: ''
      }
      this.currentDeepInfo = {}
      this.cardInfoList = [
        {
          id: +new Date(),
          name: "默认等级",
          disabled: false,
          bgiName: "default1.png"
        }
      ],
      // 默认选中的背景图uid
      this.activeBgiUid = ''
      // 默认背景图
      this.defaultBgiImgList = []
      // 自己上传的背景图片列表
      this.uploadBgiImgList = []
    }
  },
  mounted() {
    this.resetData()
  },
  props: {
    item: {
      default: {}  // 待编辑的会员卡类型信息
    },
    canDisabledDefault: { 
      default: false  // 是否强制设置为默认类型
    }
  },
  computed: {
    title() {
      let title = ''
      switch (this.status){
        case 1:
          title = this.item.id ? '编辑卡类型' : '新增卡类型'
          break
        case 2:
          title = this.subStatus == 1 || this.subStatus == 3 ? '新增等级' : '修改封面'
          break
      }
      return title;
    }
  },
  // watch: {
  //   showDrawer: {
  //     handler(newVal) {
  //       this.show = newVal;
  //       if(newVal) {
  //         this.resetData()
  //         if(this.item.id) {
  //           // 编辑
  //           this.getEditInfoHandle()
  //         }
  //       } else {
  //         this.$emit('getTableData')
  //       }
  //     },
  //     immediate: true
  //   }
  // }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/common/elementFormBtnVip.less";
@import "../../../style/common/scrollBarVip.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/vip/drawerAddOrUpdateVipType.less";
</style>