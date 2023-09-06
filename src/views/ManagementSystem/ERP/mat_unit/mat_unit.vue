<template>
    <div class="mat_unit">
        <!-- <div class="mat_unit-headline">物料单位</div> -->
        <div class="mat_unit-controller">
            <icon-button @click.native="xingh" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#f5f5f5"></icon-button>
            <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"  bjcolors="#491E24"></icon-button>
        </div>


        <div style="display: inline-block;" id="allexportareport" class="meisfgr">
            <table class="zhuixiaoi"   style="min-width: 1414px;">
                <thead class="mmodity">
                    <tr>
                        <th  >
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="handleCheckAllChange">全选</el-checkbox>
                        </th>
                        <th>单位名称</th>
                        <!-- <th>单位类型</th>
                        <th>比例</th> -->
                        <th>状态</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                    </tr>
                </thead>
                <tbody class="limiting" :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in tableData" :key="item.id" class="drag-list"
                        :class="multipleSelection.includes(item.id)? 'drag-list-check':''">
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                                <el-checkbox  :label="item.id">{{i+1}}</el-checkbox>
                            </el-checkbox-group> 
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <!-- <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.un || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.us || '-----'"></ellipsis-tooltip>
                        </td> -->
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.s || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                        </td>
                        <td  :style="{'color':item.s=='无效'?'#595959':'',}">
                            <ellipsis-tooltip :text="item.u || '-----'"></ellipsis-tooltip>
                        </td>
                    </tr>
                    <!-- <tr class="drag-list" v-if="tableData.length<1">
                        <td class="nodata">
                            <img src="../../../../assets/img/wu.png" alt="">
                            <div class="hint">暂无数据</div>
                        </td>
                    </tr> -->
                </tbody>
            </table>
            <div class="tiaodd" v-if="tableData.length<1">
                <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
                    <img src="../../../../assets/img/wu.png" alt="">
                    <div class="hint">暂无数据</div>
                </td>
            </div>      
        </div>



        <!-- 新增  编辑-->
        <div v-show="dialogFormVisible" class="dialogFormVisible">
            <el-dialog :title="title?'新增单位':'编辑单位'"  @close="dialogFormVisible = false" :visible.sync="dialogFormVisible"  :close-on-click-modal="false">
                <el-form label-position="left">
                    <!-- <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory ">
                                <span class="reqfieldsd">*</span>单位类型：
                            </div>
                            <div class="controlling harness">
                                <el-radio v-model="unit.type" label="1">基本单位</el-radio>
                                <el-radio v-model="unit.type" label="2">复合单位</el-radio>
                            </div>
                        </div>
                        <div class="layouts">&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;基本单位为最小计量单位</div>                
                        <div class="layouts">&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;复合单位需设置与基本单位的比例</div>                
                    </div> -->
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>单位名称：
                            </div>
                            <!-- <div class="party" v-if="!showquantity"  >
                                <div class="sdfrfd">
                                    <el-input v-model="unit.name" placeholder="输入单位名称" @blur="limitingRule(0)" ref="selectsse" class="figuresizes"/>
                                    <div class="cwts" v-if="!showquantity">{{mistake[0]}}</div>
                                </div>
                                <div class="daxiao">=</div>
                                <div class="sdfrfd" style="width:140px;">
                                    <el-input v-model="unit.quantity" placeholder="填写数字" @blur="limitingRule(2)" ref="selectsse2"  class="figuresize"/>
                                    <div class="cwts" v-if="!showquantity">{{mistake[2]}}</div>
                                </div>
                                <div class="daxiao">×</div>
                                <div class="sdfrfd">
                                    <el-select v-model="unit.basicUnit" placeholder="-请选择基本单位-"  @change="limitingRule(1)"  ref="selectsse1" class="figuresizes" clearable>
                                        <el-option v-for="each in basicunits" :key="each.id" :label="each.n" :value="each.id"></el-option>
                                    </el-select>
                                    <div class="cwts" v-if="!showquantity">{{mistake[1]}}</div>
                                </div>
                            </div> -->
                            <el-input v-if="showquantity" v-model="unit.name"  @blur="limitingRule(3)" placeholder="输入单位名称" ref="selectsse3" class="controlling" />                     
                            <div class="cwts" v-if="showquantity">{{mistake[3]}}</div>
                        </div>
                        
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFormVisible = false">取消</el-button>
                    <el-button v-show="title" type="primary" @click="construction">新建</el-button>
                    <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 无效有效删除 -->
        <div v-show="dialogFible" class="diagrgeesfelogFor">
            <el-dialog :title="srnr" :visible.sync="dialogFible" @close="dialogFible = false" :close-on-click-modal="false">
                <div class="wwent" v-show="cwsm.cs.length>0">
                    <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
                    <characters-button @click.native="synchronizon" :disaed="kzsfjy" colors="#f5f5f5" :wz="`同步${srnr}`"></characters-button>
                </div>
                <div class="wentlb" v-show="cwsm.cs.length>0">
                    <table class="zhuixiaoi"  >
                        <thead class="mmodity">
                            <tr>
                                <th>序号</th>
                                <th>说明</th>
                                <th>处理结果</th>
                            </tr>
                        </thead>
                        <tbody class="limiting"  :style="{'width':cwsm.cs.length>6?'calc(100% + 6px)':'100%'}">
                            <tr v-for="(item,i) in cwsm.cs"  :key="i" class="drag-list" >
                                <td>{{i+1}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                                </td>
                                <td v-show="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</td>
                                <td v-show="item.jg == '---'">{{item.jg}}</td>
                                <td v-show="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <div class="wwent" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
                <div class="wentlb danykz" v-show="cwsm.ns.length>0">
                    <table class="zhuixiaoi"  >
                        <thead class="mmodity">
                            <tr>
                                <th>序号</th>
                                <th>说明</th>
                            </tr>
                        </thead>
                        <tbody class="limiting"  :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
                            <tr v-for="(item,i) in cwsm.ns"  :key="i" class="drag-list" >
                                <td>{{i+1}}</td>
                                <td>
                                    <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="dialogFible = false">关闭</el-button>
                </span>
            </el-dialog>
        </div>
    </div>
</template>
<script>
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import CharactersButton from '@/components/CharactersButton.vue'//根据路径导入组件
export default {
    data(){
        return{
            tableData: [],//物料规格目录
            dialogFormVisible:false,//控制新建物料规格是否显示
            materialStair:"",//物料规格名字
            title:true,//为新建还是编辑
            unit:{
                type:"1",//类型
                name:"",//名称
                quantity:"1",//数量
                basicUnit:"",//基本单位 
            },//
            basicunits:[],//基本单位列表
            showquantity:true,//控制数量是否显示  

            multipleSelection: [],// 选中的内容
            isIndeterminate:false,// 供应商选择一部分
            checkAll:false,//供应商全选

            dialogFible:false,//控制错误2是否显示
            srnr:'',//文案
            cwsm:{
                ns:[],//不可操作列表
                cs:[],//可一键操作列表
            },//错误2说明
            kzsfjy:false,//控制同步按钮是否禁用
            mistake:[],//弹窗内错误提示

            windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
            windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
            MaxHeight:0,//滚动高度
            MaxNumber:0//最大个数
        }
    },
    mounted(){
        this.demand()
        // console.log(w);
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
    filters:{
        pand:function(v){
            if(v == '置为无效'){
                return '无效';
            }else if(v == '置为有效'){
                return '有效';
            }else if(v == '批量删除'){
                return '删除';
            }
            
        }
    },
    components:{
        IconButton,
        EllipsisTooltip,
        CharactersButton
    },
    computed:{
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
                console.log(this.$overall.character(this.unit.name));
                this.$refs.selectsse.$refs.input.style.borderColor = '#CE4253'
                if(this.unit.name == ''){
                    this.mistake.splice(i,1,'输入单位名称')
                }else{
                    if(this.$overall.character(this.unit.name) > 10){
                        this.mistake.splice(i,1,'输入文字长度超过5')
                    }else{
                        this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                        this.mistake.splice(i,1,'')                        
                    }
                }
                break
              case 1: 
                console.log(this.$refs.selectsse1);
                this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#CE4253'
                if(this.unit.basicUnit == ''){
                    this.mistake.splice(i,1,'请选择基本单位')
                }else{
                    this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#555763'
                    this.mistake.splice(i,1,'')                        
                }             
                break
              case 2: 
                // console.log(this.$overall.character(this.unit.name));
                this.$refs.selectsse2.$refs.input.style.borderColor = '#CE4253'
                if(this.unit.quantity == ''){
                    this.mistake.splice(i,1,'填写数字')
                }else{
                    if(isNaN(Number(this.unit.quantity))){
                        this.mistake.splice(i,1,'请填写纯数字')
                    }else{
                        if(!/^\d+$/.test(this.unit.quantity)){
                            this.mistake.splice(i,1,'请填写整数')
                        }else{
                            if( this.unit.quantity > 100 || this.unit.quantity < 1){
                                this.mistake.splice(i,1,'只允许填写1-100')
                            }else{

                                this.$refs.selectsse2.$refs.input.style.borderColor = '#555763'
                                this.mistake.splice(i,1,'')                        
                            }                             
                        }
                       
                    }

                }
                break
              case 3: 
                this.$refs.selectsse3.$refs.input.style.borderColor = '#CE4253'
                if(this.unit.name == ''){
                    this.mistake.splice(i,1,'输入单位名称')
                }else{
                    if(this.$overall.character(this.unit.name) > 10){
                        this.mistake.splice(i,1,'输入文字长度超过5')
                    }else{
                        this.$refs.selectsse3.$refs.input.style.borderColor = '#555763'
                        this.mistake.splice(i,1,'')                        
                    }
                }
                break
            }
        },
        // 重置规则样式
        czyangs(){
            this.$nextTick(()=>{  //次要代码
                this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#555763'
                this.$refs.selectsse2.$refs.input.style.borderColor = '#555763'
                this.$refs.selectsse3.$refs.input.style.borderColor = '#555763'
            })
        },
        //获取焦点
        edit(){
            this.$nextTick(()=>{  //次要代码
              this.$refs.selectsse3.focus();
              console.log(this.$refs);
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
        // 获取一级分类内容  标记
        demand(){
            this.$api.ERP.mat_unit.requestmat_unitlist().then(res=>{
                console.log(res);
                if(res.code == 1){
                    this.tableData = res.data || []
                    var s = []
                    for (const iterator of this.tableData) {
                        s.push(iterator.id)
                    }
                    for(var i = 0;i<this.multipleSelection.length;i++){
                        if(s.indexOf(this.multipleSelection[i]) == -1){
                            this.multipleSelection.splice(i,1)
                        }
                    }
                }else{
                    this.$message.warning(res.msg)
                }
            })

        },
        // 为空
        weik(){
            this.multipleSelection= []
            this.isIndeterminate=false
            this.checkAll=false
        },
        // 选择全选或取消
        handleSelectionChange(val) {
            this.multipleSelection = []
            for (const key in val) {
                this.multipleSelection.push(val[key].id)
            }
        },
        // 点开创建为空
        xingh(){
            // this.$api.ERP.mat_unit.requestmat_unitget({id:0}).then(res=>{
                // console.log(res.data.base_units);
                // this.basicunits = res.data.base_units
                this.dialogFormVisible = true 
                this.title = true
                this.unit.type = '1'
                this.unit.name = ''
                this.unit.quantity = '1'
                this.unit.basicUnit = '' 
                this.mistake = [] 
                
                this.$nextTick(()=>{  //次要代码
                    this.$refs.selectsse3.$refs.input.style.borderColor = '#555763'
                    this.$refs.selectsse3.focus();
                })       
            // })
        },
        // 新建
        construction(){
            if(this.unit.type == 1){
                this.limitingRule(3)
            }else{
                this.limitingRule(0)
                this.limitingRule(1)
                this.limitingRule(2)
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
                if(this.unit.type == 1){
                    this.unit.quantity = ''
                    this.unit.basicUnit = ''
                }
                this.fqqhqxx()
            }
        },
        // 新建单位
        fqqhqxx(){
                this.$api.ERP.mat_unit.requestmat_unitnew({
                    name:this.unit.name
                }).then(res=>{
                    console.log(res); 
                    if(res.code == 1){
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                        this.weik()
                        this.demand()
                        this.dialogFormVisible = false
                    }else if(res.code == 6){
                        this.$message({
                            showClose:true,
                            message:"创建成功，状态无效，"+res.msg,
                            type:'warning'
                        })
                        this.weik()
                        this.demand()
                        this.dialogFormVisible = false
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
        },
        // 获取编辑内容
        compileprinter(){
            if(this.multipleSelection.length == 1){
                    this.unit.name = this.tableData.find(item => item.id == this.multipleSelection[0]).n
                    this.title = false
                    this.dialogFormVisible = true
                    
            }else {  
                this.$message({
                    message: '请选择一个进行编辑',
                    type: 'warning',
                })
            }
        },
        // 保存编辑内容
        saveprinter(){
            if(this.unit.type == 1){
                this.limitingRule(3)
            }else{
                this.limitingRule(0)
                this.limitingRule(1)
                this.limitingRule(2)
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
                if(this.unit.type == 1){
                    this.unit.quantity = ''
                    this.unit.basicUnit = ''
                }
                this.$api.ERP.mat_unit.requestmat_unitsave({
                    id:this.multipleSelection[0],
                    name:this.unit.name.toString()
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
                        this.weik()
                    }else{
                        this.$message.warning(res.msg)
                    }
                })
            }
        },
        // 重试
        chdefrs(){
            if(this.srnr == '置为无效'){
                this.noneffective()
            }else if(this.srnr == '置为有效'){
                this.effective()
            }else if(this.srnr == '批量删除'){
                this.printerdel()
            }
        },
        // 同步
        synchronizon(){
            this.kzsfjy = true 
            var s = ''
            if(this.srnr == '置为无效'){
                s = 2
            }else if(this.srnr == '置为有效'){
                s = 1
            }else if(this.srnr == '批量删除'){
                s = 3
            }
            var tid= []
            var id= []
            for (const iterator of this.cwsm.cs) {
                tid.push(iterator.tid)
                id.push(iterator.id)
            }
            console.log(tid,id,s);
            this.$api.ERP.mat_unit.requestmat_unitob({
                op_status:Number(s),
                type_ids:tid,
                ids:id
            }).then(res=>{
                console.log(res);
                if(res.code ==1){
                    for (const key in this.cwsm.cs) {
                        this.cwsm.cs[key].jg = '成功'
                    }
                    this.demand()
                    if(this.cwsm.ns.length<1){
                        this.chdefrs()
                    }
                }else if(res.code ==2){
                    for (const key in this.cwsm.cs) {
                        for (const keys in res.data) {
                            if(this.cwsm.cs[key].id == res.data[keys].id){
                                this.cwsm.cs[key].jg = '失败'
                            }
                        }
                    }
                    for (const key in this.cwsm.cs) {
                        if(this.cwsm.cs[key].jg == '---'){
                            this.cwsm.cs[key].jg = '成功'
                        }
                    }
                }else{
                    this.$message.warning(res.msg) 
                }
            })
        },
        // 无效
        noneffective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_unit.requestmat_unitdisable({ids:this.multipleSelection}).then(res=>{
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '置为无效'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请选择一个进行更改") 
            }
        },
        // 有效
        effective(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_unit.requestmat_unitenable({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '置为有效'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })
            }else{
                this.$message.warning("请选择一个进行删除") 
            }
        },
        // 删除
        printerdel(){
            if(this.multipleSelection.length > 0){
                this.$api.ERP.mat_unit.requestmat_unitdel({ids:this.multipleSelection}).then(res=>{
                    console.log(res);
                    if(res.code ==1){
                        this.demand()
                        this.weik()
                        this.dialogFible= false
                        this.$message({
                            showClose:true,
                            message:"操作成功",
                            type:'success'
                        })
                    }else if(res.code == 2){
                        this.dialogFible=true
                        this.kzsfjy=false
                        this.srnr = '批量删除'
                        this.cwsm.ns = res.data.ns||[]
                        for (const key in res.data.cs) {
                            res.data.cs[key].jg = '---'
                        }
                        this.cwsm.cs = res.data.cs||[]
                    }else{
                        this.$message.warning(res.msg) 
                    }
                })                
            }else{
                this.$message.warning("请选择一个进行删除") 
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
        units(){
            return JSON.parse(JSON.stringify(this.unit))
        },
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
        // 监听批量预览
        units:{
            deep:true,
            handler:function(after,before){
                // console.log(after.quantity);
                // console.log(before.quantity);
                if(after.type != before.type){
                    
                    this.mistake = [] 
                    if(after.type == 1){
                        this.showquantity = true
                        this.$nextTick(()=>{
                            this.$refs.selectsse3.focus();
                            this.$refs.selectsse3.$refs.input.style.borderColor = '#555763'
                        })
                    }else{
                        this.$nextTick(()=>{
                            this.$refs.selectsse.$refs.input.style.borderColor = '#555763'
                            this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#555763'
                            this.$refs.selectsse2.$refs.input.style.borderColor = '#555763'
                            this.$refs.selectsse.focus();
                        })
                        this.showquantity = false
                    }       
                }
                // if(this.$refs.selectsse1){
                //     if(after.basicUnit == ''){
                //         this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#CE4253'
                //         this.mistake.splice(1,1,'请选择基本单位')
                //     }else{
                //         this.$refs.selectsse1.$el.children[0].children[0].style.borderColor = '#555763'
                //         this.mistake.splice(1,1,'')                        
                //     }
                // }

                // console.log(after.quantity < 101);
                // console.log(after.quantity > 0);
                // if(after.quantity > 100 || after.quantity < 1){
                //     this.unit.quantity = before.quantity
                //     this.$message.warning('只允许填写1-100')
                // }

            }
        }

    }
 
}
</script>
<style>
    .mat_unit{
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding:20px 30px;
    } 
    /* 必填 */
    .mat_unit .mandatory{
        color: #40404e ;
        width: 140px;
        text-align: right;
        line-height: 34px;
    }
    .mat_unit .controlling{
        width: 230px !important;
        /* line-height: 40px; */
    }
    .mat_unit .harness{
        display: flex;
        align-items: center;
    }
    .sdfrfd{
        /* height: 70px; */
        width:160px ;
        display: flex;
        flex-wrap: wrap;
    }
    .sdfdgr{
        display: flex;
        flex-wrap: wrap;
    }
    .cwts{
        color: #CE4253 ;
        line-height: 34px;
        padding-left: 10px;
    }
    .mat_unit .reqfieldsd{
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    /* 表格无数据时展示 */
    .mat_unit .tiaodd{
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
    .mat_unit .nodata{
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
    }
    .mat_unit .nodata img{
        width: 60px;
        height: 60px; 
    }
    .mat_unit  .nodata .hint{
        line-height: 36px;
        font-size: 13px  !important;
    }
    /* 单选框 */
    .mat_unit .el-radio{
        display: flex;
        align-items: flex-end;
    }
    /* 表格全选字体颜色 */
    .mat_unit .zhuixiaoi .el-checkbox__label{
        color: #40404e ;
    }
    .mat_unit .zhuixiaoi .mmodity .el-checkbox__label{
        font-size: 12px;
    }

    .mat_unit .mat_unit-headline{
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }
    .mat_unit .mat_unit-controller{
        height: 54px;
        width:100%;
        background-color: #eee;
        display: flex;
        align-items: center;
    }
    .mat_unit .layouts{
        font-size: 13px;
        padding-top: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }

    .mat_unit .compatibil{
        margin-bottom: 20px;
        
    }
    .mat_unit .el-form-item__content{
        display: flex;
    }
    .mat_unit .compatibility{
        display: flex;
        /* align-items: center; */
        /* margin-bottom: 5px; */
    }
    .mat_unit .figuresize{
        width: 140px !important;
    }
    .mat_unit .figuresizes{
        width: 160px !important;
    }
    .mat_unit .daxiao{
        font-size: 20px;
        color: #40404e;
        margin: 6px 10px;
    }
    .mat_unit .required{
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    /* 取消按钮 */
    .mat_unit .el-dialog .el-button--default{
        background-color: #ccc ;
        border: 1px solid #ccc;
        color: #40404e;
    } 

    /* 改限制字体数量的颜色背景 */
    .mat_unit .el-input .el-input__count .el-input__count-inner{
        background: none;
        color: #40404e;
    }
    /* 让等多个input在同一行上 */
    .mat_unit .party{
        display: flex;
        align-items: flex-start;
    }

    /* 靠右 */
    .mat_unit  .el-dialog{
        margin: 0px 0px 0px auto !important;
        height: 100%;
        position: relative;
    } 

    .mat_unit  .el-dialog__footer{
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }
    .mat_unit  .el-dialog__body{
        padding:0px 0px 30px 20px ;
        overflow-y: scroll !important;
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
        
    }

    .mat_unit .dialogFormVisible .el-dialog{
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .mat_unit .el-dialog{
        background-color: #f9f9f9;
    }
    .mat_unit .el-radio__label{
        color: #40404e;
    }

    .mat_unit .el-input__inner{
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }
    .mat_unit .el-dialog__title,.mat_unit .el-dialog__headerbtn .el-dialog__close,.mat_unit .el-form-item__label{
         color: #1a1a21;
    }
    .mat_unit .el-input{
        width: 100%;
    }
    .mat_unit .el-form-item{
        display: flex;
        margin: 0;
        align-items: center;
    }
    /* 改变多选框背景颜色和上下间距 */
    .mat_unit .el-checkbox-group{
        display: flex;
        align-items: flex-end;
        justify-content: left;
    }
    .mat_unit .el-checkbox__input{
        background-color: rgba(0, 0, 0, 0);
    }

    .mat_unit table thead tr th,.mat_unit table tbody tr td{
        height: 40px;
        font-size: 14px;
    } 


    /* 下拉框 */
    .el-select-dropdown__wrap{
        background-color: #f5f5f5;
    }
    .el-select-dropdown__empty{
        background-color: #f5f5f5;
        color: #40404e;
    }
    .el-select-dropdown__item.selected{
        background-color: #e5e5e5;
    }
    .el-select__popper.el-popper[role="tooltip"]{
        border: 1px solid #f5f5f5;
    }
    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before{
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }
     .el-select-dropdown__item.hover, .el-select-dropdown__item:hover{
        background-color: #e5e5e5;
    }
     .el-select-dropdown__item.selected{ 
        color: #40404e;
    }
     .el-select-dropdown__item{
        color: #40404E
    }
    .el-select-dropdown{
        border: 1px solid #f5f5f5;
    }
    .el-select-dropdown__empty{
        background-color: #f5f5f5;
    }
/* 错误2 */    
    .mat_unit .diagrgeesfelogFor .el-dialog{
        width: 720px;
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0,0.1)
    }
    .mat_unit .diagrgeesfelogFor .wwent{
        color: #ce4153;
        font-size: 14px;
        margin: 20px 0px 20px 20px;
        display: flex;
        align-items: center;
    }
    .mat_unit .diagrgeesfelogFor .wentlb{
        margin-left: 20px;
        width: 640px;
    }    
    .mat_unit .diagrgeesfelogFor .zhuixiaoi{
        width: 100%;
    }
    .mat_unit .diagrgeesfelogFor .zhuixiaoi .limiting{
        max-height: 280px !important;
        overflow-y: auto !important;
    }
    .mat_unit .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),.mat_unit .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1){
        width: 50px;
    }
    .mat_unit .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),.mat_unit .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2){
        width: 320px;
    }
    .mat_unit .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),.mat_unit .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3){
        width: 200px;
    }
    .mat_unit .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),.mat_unit .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2){
        width: 520px;
    }
    /* 无效颜色 */
    .mat_unit .diagrgeesfelogFor .el-button--primary.is-disabled,.mat_unit .diagrgeesfelogFor .el-button--primary.is-disabled:hover{
        background-color: #1F2846;
        color: #4e505a;
        border-color: #1F2846;
    }

/* 仓库列表 */
    .mat_unit .meisfgr{
        width:100%;
        overflow-x: scroll;
    }
    .mat_unit .zhuixiaoi{
        width:100%;
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e ;  
    }
    .mat_unit .zhuixiaoi .mmodity tr th{
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
        padding-left: 20px;
    }
    .mat_unit .zhuixiaoi .mmodity tr th .el-checkbox__label{
        font-size: 14px;
        font-weight: 600;
        color: #40404e;
    }
    .mat_unit .zhuixiaoi .limiting .drag-list td{
        height: 36px;
        line-height: 36px;
        text-align: left;
        font-size: 14px;
        font-weight:400;
        padding-left: 20px;
    }
    .mat_unit .zhuixiaoi .limiting .drag-list{
        display:block;
        display: flex;
        border-top: solid 1px #f5f5f5;
        
    }
    .mat_unit .zhuixiaoi .mmodity{
        width: 100%;
        display:block;
    }
    .mat_unit .zhuixiaoi .mmodity tr{
        display: flex;
        background-color: #f5f5f5; 
    }
    .mat_unit .zhuixiaoi .limiting{
        overflow-y: auto !important;
        max-height: 540px ;
        border-bottom: solid 1px #f5f5f5;
        display:block;
    }
    .mat_unit .drag-list td:nth-of-type(1),.mat_unit .mmodity th:nth-of-type(1){
        width: 70px;
    }
    .mat_unit .mmodity th:nth-of-type(2), .mat_unit .drag-list td:nth-of-type(2){
        width: 300px;
    }
    .mat_unit .drag-list td:nth-of-type(3),.mat_unit .mmodity th:nth-of-type(3){
        width: 200px;
    }
    .mat_unit .drag-list td:nth-of-type(4),.mat_unit .mmodity th:nth-of-type(4){
        width: 200px;
    }
    .mat_unit .drag-list td:nth-of-type(5),.mat_unit .mmodity th:nth-of-type(5){
        width: 200px;
    }
    .mat_unit .drag-list td:nth-of-type(6),.mat_unit .mmodity th:nth-of-type(6){
        width: 200px;
    }
    .mat_unit .drag-list td:nth-of-type(7),.mat_unit .mmodity th:nth-of-type(7){
        width: 100px;
    }
    .mat_unit .drag-list:nth-of-type(odd) {
        background-color: #f9f9f9 ;
        color: #40404e ;
    }
    .mat_unit .drag-list:nth-of-type(even) {
        background-color: #f5f5f5;
        color: #40404e ;
    }

    .drag-list-check {
        /* background: rgba(39, 52, 82, .5) !important; */
    }

</style>


