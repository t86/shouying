<template>
    <div class="store">
        <!-- <div class="store-headline">宽{{windowWidt}}，高{{windowHeigh}}</div> -->
        <div class="store-controller">
            <icon-button @click.native="xingh" text="新增erp仓库" img="btn_add.png" colors="#383943"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
        </div>
        <div class="zsykd"  style="display: inline-block;" >
            <table class="zhuixiaoi"  style="min-width: 1191px;">
                <thead class="mmodity">
                    <tr>
                        <th>
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">全选</el-checkbox>
                        </th>
                        <th>仓库名称</th>
                        <th>仓库描述</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
                    </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData"  :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':'#40404e'}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox  :label="item.id">{{i+1}}</el-checkbox>
                            </el-checkbox-group> 
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.u || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                        </td>
                    </tr>
                </tbody>
            </table> 
            <div class="tiaodd" v-if="tableData.length<1">
                <td class="nodata">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>            
        </div>
        <!-- 新增仓库 -->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="kongzixians?'新增erp仓库':'编辑erp仓库'" :visible.sync="dialogFormVisible" @close="dialogFormVisible = false" :close-on-click-modal="false">
                <el-form label-position="left">
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd">*</span>erp仓库名称：
                        </div>      
                        <el-input  v-model="ProductLibrary.name" @blur="limitingRule(0)" ref="selectsse"  placeholder="请输入erp仓库名称" class="controlling" />       
                        <div class="cwts">{{mistake[0]}}</div>
                    </div>
                    <div class="compatibility">
                        <div class="mandatory">
                            <span class="reqfieldsd"></span>erp仓库描述：
                        </div>  
                        <el-input type="textarea" v-model="ProductLibrary.remark"  @blur="limitingRule(1)"  ref="selectsse1"  :rows="3" class="controlling" placeholder="请输入erp仓库描述" ></el-input>
                        <div class="cwts">{{mistake[1]}}</div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button type="primary" v-show="kongzixians" @click="construction">新建</el-button>
                    <el-button type="primary" v-show="!kongzixians" @click="saveprinter">保存</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false" :close-on-click-modal="false">
                <div class="wwent">以下对象存在依赖，需人工处理依赖</div>
                <div class="wentlb">
                    <table class="zhuixiaoi"  >
                        <thead class="mmodity">
                            <tr>
                                <th>序号</th>
                                <th>说明</th>
                            </tr>
                        </thead>
                        <tbody class="limiting"  :style="{'width':cwsm.ns.length>16?'calc(100% + 6px)':'100%'}">
                            <tr v-for="(item,i) in cwsm.ns"  :key="i" class="drag-list" >
                                <td>{{i+1}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                                </td>
                            </tr>
                            <tr class="drag-list"  v-if="cwsm.ns.length<1">
                                <td class="nodata">
                                    <img src="../../../../assets/img/wu.png" alt="">
                                    <div class="hint">暂无数据</div>
                                </td>
                            </tr>

                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFible = false">取消</el-button>
                </span>
            </el-dialog>
        </div>

    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
export default {
    data(){
        return{
            tableData: [],//仓库目录
            dialogFormVisible:false,//控制新建仓库是否显示
            ProductLibrary:{
                name:'',//仓库名称
                remark:'',//描述
            },//仓库
            multipleSelection: [],// 选中的内容
            isIndeterminate:false,// 仓库选择一部分
            checkAll:false,//仓库全选

            kongzixians:true,//控制显示新建还是编辑

            dialogFible:false,//控制错误2是否显示
            srnr:'',//文案
            cwsm:{
                ns:[],
                cs:[],
            },//错误2说明
            mistake:[],//弹窗内错误提示

            windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
            windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
            MaxHeight:0,//滚动高度
            MaxNumber:0//最大个数
        }
    },
    mounted(){
        this.demand()
        this.RollMaxHeight(this.windowHeigh)
        var that = this;
        window.onresize = () => {
            return (() => {
                window.fullHeight = document.documentElement.clientHeight;
                window.fullWidth = document.documentElement.clientWidth;
                that.windowHeigh = window.fullHeight;  // 高
                that.windowWidt = window.fullWidth; // 宽
            })()
        };
    },
    computed:{
    }, 
    components: {
        EllipsisTooltip,
        IconButton
    },
    filters:{
    },
    methods: {
        // 输入规则
        limitingRule(i){
            for(var s = 0;s<i+1;s++){
                if(this.mistake[s] == undefined){
                    this.mistake.push('')
                }
            }
            switch (Number(i)) {
              case 0: 
                console.log(this.$overall.character(this.ProductLibrary.name));
                this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
                if(this.ProductLibrary.name == ''){
                    this.mistake.splice(i,1,'请输入erp仓库名称')
                }else{
                    if(this.$overall.character(this.ProductLibrary.name) > 20){
                        this.mistake.splice(i,1,'输入文字长度超过10')
                    }else{
                        this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                        this.mistake.splice(i,1,'')                        
                    }
                }
                break
              case 1: 
                console.log(this.$overall.character(this.ProductLibrary.remark));
                this.$refs.selectsse1.$refs.textarea.style.borderColor = '#CE4253'
                if(this.$overall.character(this.ProductLibrary.remark) > 280){
                    this.mistake.splice(i,1,'输入文字长度超过140')
                }else{
                    this.$refs.selectsse1.$refs.textarea.style.borderColor = '#555763'
                    this.mistake.splice(i,1,'')                        
                }             
                break
              case 2: 
                break
            }
        },
        // 重置规则样式
        czyangs(){
            this.$nextTick(()=>{  //次要代码
                this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                this.$refs.selectsse1.$refs.textarea.style.borderColor = '#555763'
            })
        },

        // 获取epr仓库列表
        demand(){
            this.$api.ERP.store.requeststorelist().then(res=>{
                console.log(res);
                if(res.code == 1){
                    this.tableData = res.data || []
                }else{
                    this.$message.warning(res.msg)
                }
            })
        },
        // 选择全选或取消
        handleCheckAllChange(val) {
            if(val){
                this.multipleSelection = []
                for (const key in this.tableData) {
                    this.multipleSelection.push(this.tableData[key].id)
                }
            }else{
                this.multipleSelection = []
            }
            this.isIndeterminate = false;
        },
        // 控制单个选中 
        handleCheckedCitiesChange(value) {
            console.log(value);
            let checkedCount = value.length;
            this.checkAll = checkedCount === this.tableData.length;
            this.isIndeterminate = checkedCount > 0 && checkedCount < this.tableData.length;
            // console.log(this.checkedCities);
        },

        // 点开创建仓库
        xingh(){
            this.mistake = []
            this.czyangs()
            this.dialogFormVisible = true 
            this.ProductLibrary.name = ''
            this.ProductLibrary.remark = ''
            this.kongzixians =true
            this.edit()
        },
        // 创建仓库
        construction(){
            for(var i=0;i<2;i++){
                this.limitingRule(i)
            }
            var fany = false
            for (const iterator of this.mistake) {
                if(iterator != ''){
                    fany = true
                }
            }
            if(fany){
                this.$message.warning('请按提示正确填写')
            }else{
                this.$api.ERP.store.requeststorenew({
                    name:this.ProductLibrary.name,
                    remark:this.ProductLibrary.remark,
                }).then(res=>{
                    console.log(res);
                    if(res.code == 1){
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                        this.demand()
                        this.dialogFormVisible = false
                        this.ProductLibrary.name = ''
                        this.ProductLibrary.remark = ''
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
            }
        },
        //获取焦点
        edit(){
            this.$nextTick(()=>{  //次要代码
                // console.log(this.$refs);
                this.$refs.selectsse.focus();
            })
        },
        // 编辑内容
        compileprinter(){
            if(this.multipleSelection.length == 1){
                this.czyangs()
                this.$api.ERP.store.requeststoreget({id:this.multipleSelection[0]}).then(res=>{
                    console.log(res);
                    this.kongzixians = false
                    this.ProductLibrarys = res.data.mklibs
                    this.ProductLibrary={
                        name:res.data.name,
                        remark:res.data.remark
                    }
                    this.mistake = []
                    this.edit()
                    this.dialogFormVisible = true
                })
            }else {  
                this.$message({
                    message: '请选择一个进行编辑',
                    type: 'warning',
                })
            }
        },
        // 保存编辑内容
        saveprinter(){
            for(var i=0;i<2;i++){
                this.limitingRule(i)
            }
            var fany = false
            for (const iterator of this.mistake) {
                if(iterator != ''){
                    fany = true
                }
            }
            if(fany){
                this.$message.warning('请按提示正确填写')
            }else{
                this.$api.ERP.store.requeststoresave({
                    id:this.multipleSelection[0],
                    name:this.ProductLibrary.name,
                    remark:this.ProductLibrary.remark,
                }).then(res=>{
                    console.log(res);
                    if(res.code == 1){
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                        this.demand()
                        this.dialogFormVisible = false
                        this.ProductLibrary.name = ''
                        this.ProductLibrary.remark = ''
                        this.multipleSelection = []
                        this.isIndeterminate = false
                        this.checkAll = false
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
            }
        },
        // 无效
        noneffective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.store.requeststoredisable({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.multipleSelection = []
                        this.isIndeterminate=false
                        this.checkAll=false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.srnr = '置为无效'
                        this.cwsm.ns = res.data.ns||[]
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请至少选择一个进行操作") 
            }

        },
        // 有效
        effective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.store.requeststoreenable({ids:this.multipleSelection}).then(res=>{
                    // console.log(res);
                    if(res.code ==1){
                        this.multipleSelection = []
                        this.isIndeterminate=false
                        this.checkAll=false
                        this.demand()
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.srnr = '置为有效'
                        this.cwsm.ns = res.data.ns||[]
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请至少选择一个进行操作") 
            }
        },
        // 删除
        printerdel(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.store.requeststoredel({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.multipleSelection = []
                        this.isIndeterminate=false
                        this.checkAll=false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.srnr = '批量删除'
                        this.cwsm.ns = res.data.ns||[]
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })                
            }else{
                this.$message.warning("请至少选择一个进行操作") 
            }

        },
        // 滚动最大高度
        RollMaxHeight(i){   
            var s = i - 48 - 60 - 55 - 37
            this.MaxHeight = s
            this.MaxNumber = Math.floor(s/37)
            console.log(this.MaxNumber);
            // console.log(i);
        }
    },
    computed:{

    },
    watch:{
        windowHeigh(val) {
            let that = this;
            this.RollMaxHeight(val)
        //   console.log("实时屏幕高度：",val, that.windowHeigh );
        },
        windowWidt (val) {
          let that = this;
        //   console.log("实时屏幕宽度：",val, that.windowWidt );
        },
    }
 
}
</script>
<style> 
    .store{
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding:20px 30px;
    }   
    .store .mandatory{
        color: #40404e ;
        width: 140px;
        text-align: right;
        line-height: 34px;
    }
    .cwts{
        color: #CE4253 ;
        line-height: 34px;
        padding-left: 10px;
    }
    .controlling{
        border-color: red;
        width: 230px !important;
        
    }
    /* 表格无数据时展示 */
    .store .tiaodd{
        position: sticky;
        left: 0;
        top: 44px;
        width: 100% !important;
        display: inline-block;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .store  .nodata{
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }
    .store  .nodata img{
        width: 60px;
        height: 60px; 
    }
    .store  .nodata .hint{
        line-height: 36px;
        font-size: 13px  !important;
    }
    .store .store-headline{
        font-size: 30px;
        font-weight: bold;
        color: #40404e ;
        
    }

    .store .store-controller{
        /* margin-top: 30px; */
        height: 54px;
        /* width: 1600px; */
        width: 100%;
        background-color: #eee;
        display: flex;
        align-items: center;
}
    .store .layouts{
        font-size: 13px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .store .AddPrincipal{
        color: #4eadfc;
        margin-right: 10px;
        /* margin-bottom: 10px; */
        display: flex;
        align-items: center;
    }
    .el-button--primary{
        color: #f7f7f7 ;
    }
    .store .compatibility{
        display: flex;
        /* align-items: center; */
        margin-bottom: 10px;
        
    }
    .store .compatibil{
        margin-bottom: 10px;
    }
    /* 必选 */
    .store .required{
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .store .reqfieldsd{
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    } 




    
    /* 靠右 */
    .store .el-dialog{
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    } 
    .store  .el-dialog__footer{
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }
    .store  .el-dialog__body{
        padding:0px 0px 30px 20px ;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }
    .store  .el-dialog{
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0,0.1)
    }

    .store .dialogFormVisible .el-dialog{
        width: 720px;
    }


    .store .el-input__inner{
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }
    .store .el-dialog__title,.store .el-dialog__headerbtn .el-dialog__close,.store .el-form-item__label{
         color: #1a1a21 ;
    }
    .store .el-form-item__label{
        display: inline-block;
        text-align: right;
    }
    .store .el-input{
        width: 100%;
    }
    .store .el-form-item{
        display: flex;
        margin: 0;
    }
    .store .el-checkbox-group{
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }
    .store .el-checkbox__input{
        background-color: rgba(0, 0, 0, 0);
    }
    .store table thead tr th,.store table tbody tr td{
        height: 62px;
        /* font-size: 16px; */
    } 

    /* 错误2 */    
    .store .diagrgeesfelogFor .el-dialog{
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0,0.1)
    }
    .store .diagrgeesfelogFor .wwent{
        color: #40404e ;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
    }
    .store .diagrgeesfelogFor .wentlb{
        margin-left: 20px;
        width: 640px;
    }    
    .store .diagrgeesfelogFor .zhuixiaoi{
        width: 100%;
    }
    .store .diagrgeesfelogFor .limiting{
        max-height: 680px !important;
        overflow-y: scroll !important;
    }
    .store .diagrgeesfelogFor .drag-list td:nth-of-type(1),.store .diagrgeesfelogFor .mmodity th:nth-of-type(1){
        width: 70px;
    }
    .store .diagrgeesfelogFor .mmodity th:nth-of-type(2), .store .diagrgeesfelogFor .drag-list td:nth-of-type(2){
        width: 500px;
    }
    /* 新增仓库 */
        /* 仓库负责人标签 */
        .cghuanh{
            width: 300px;
            display: flex;
            flex-wrap: wrap;
            /* justify-content: space-between; */
        }
        .el-tag{
            background-color: rgba(0, 0, 0, 0);
            margin-right: 10px;
            margin-bottom:10px ;
            color: #40404e;
        }
        .el-tag i{
            color: #40404e;
        }
        /* 多行文本输入框 */
        .store .el-textarea__inner{
            background-color: rgba(0, 0, 0, 0);
            color: #40404e;
            border-radius: 2px;
        }
        /* .store .el-textarea{ */
            /* overflow: hidden; */
        /* } */
        .store .el-input__count{
            background-color: #1A1A20;
            color: #40404e;
            right: -45px;
            height: 20px;
            bottom: 5px;
            line-height: 20px;
            -webkit-user-select:none;
            -moz-user-select:none;
            -ms-user-select:none;
            user-select:none;
        }

    /* 仓库列表 */
    .zsykd{
        width: 100%;
        overflow-x: scroll!important;
    }
    .store .zhuixiaoi{
        width: 100%;
        
        border-collapse: collapse;
        color: #40404e ;  
    }
    .store .zhuixiaoi .mmodity tr th{
        height: 36px;
        line-height: 36px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight:600;
        color: #40404e;
    }
    .store .zhuixiaoi .mmodity tr th .el-checkbox__label{
        font-size: 14px;
        font-weight:600;
    }
    .store .zhuixiaoi .limiting .drag-list td{
        height: 36px;
        line-height: 36px;
        text-align: left;
        padding-left: 20px;
        font-size: 14px;
        font-weight:400;
    }
    .store .zhuixiaoi .limiting .drag-list{
        display: flex;
    }
    .store .zhuixiaoi .mmodity{
        width: 100%;
        display:block;
    }
    .store .zhuixiaoi .mmodity tr{
        display: flex;
        background-color: #f5f5f5; 
    }
    .store .zhuixiaoi .limiting{
        overflow-y: auto  !important;
        /* overflow-y: overlay  !important; */
        max-height: 540px ;
        /* width: 100%; */
        display:block;
    }
    .store .drag-list td:nth-of-type(1),.store .mmodity th:nth-of-type(1){
        width: 70px;
    }
    .store .mmodity th:nth-of-type(2), .store .drag-list td:nth-of-type(2){
        width: 300px;
    }
    .store .drag-list td:nth-of-type(3),.store .mmodity th:nth-of-type(3){
        width: 200px;
    }
    .store .drag-list td:nth-of-type(4),.store .mmodity th:nth-of-type(4){
        width: 200px;
    }
    .store .drag-list td:nth-of-type(5),.store .mmodity th:nth-of-type(5){
        width: 200px;
    }
    .store .drag-list td:nth-of-type(6),.store .mmodity th:nth-of-type(6){
        width: 100px;
    }
    .store .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9 ;
        color: #40404e ;
    }
    .store .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e ;
    }
    .store .zhuixiaoi .el-checkbox__label{
        color: #40404e ;
    }
    .store .zhuixiaoi .mmodity .el-checkbox__label{
        font-size: 12px;
    }

    /* 1280-720 */
    @media screen and (max-width: 1280px){

    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }

</style>

