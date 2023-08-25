<template>
<!-- 不用修改的文件  无效 -->
    <div class="Prd">
        <div v-if="classify.stairSecond[classify.stairfl]">
            <div class="stairfl">
                <div class="classification">一级分类</div>
                <div class="stairastrict">
                    <el-radio-group v-model="classify.stairfl" class="container">
                        <el-radio-button v-for="(enter, i) in classify.stairSecond" :key="enter.id" :label="i">
                            <div class="el-radio-button__inner-div" :style="{'color':enter.s==2? '#595959':''}">
                                {{enter.n}}
                            </div>
                        </el-radio-button>
                    </el-radio-group>
                </div>
            </div>
            <div class="stairfl" v-if="classify.stairSecond[classify.stairfl].ss">
                <div class="classification">二级分类</div>
                <div class="stairastrict" style="line-height: 42px;" v-show="this.pdddymy">
                    <el-radio-group v-model="classify.Secondfl" class="container">
                        <el-radio-button
                                v-for="(enter, i) in (this.classify.stairSecond.length>0?this.classify.stairSecond[this.classify.stairfl].ss:[])"
                                :key="enter.id" :label="i">
                            <div class="el-radio-button__inner-div" :style="{'color':enter.s==2? '#595959':''}">
                                {{enter.n}}
                            </div>
                        </el-radio-button>
                    </el-radio-group>

                </div>
                <div class="fl" v-show="!this.pdddymy">请先创建二级分类</div>
            </div>
            <div class="zsykd" style="display: inline-block;">
                <table class="zhuixiaoi" v-if="classify.stairSecond[classify.stairfl].ss">
                    <div class="Prd-controller" v-if="classify.stairSecond[classify.stairfl].ss">
                        <icon-button @click.native="VolumeProduction" text="新增单品" img="新增单品.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="newsetmeal" text="新增套餐" img="新增套餐.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="staircompile" text="编辑" img="编辑.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="noneffective" text="置为无效" img="无效.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="effective" text="置为有效" img="有效.png" colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="DelPayChannel" text="批量删除" img="删除.png" colors="#6B2830"
                                     bjcolors="#491E24"></icon-button>
                    </div>
                    <thead class="mmodity">
                    <tr>
                        <th style="border-left:1px solid #f5f5f5">
                            <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll"
                                         @change="handleCheckAllChange">行号
                            </el-checkbox>
                        </th>
                        <th>商品名称</th>
                        <th>拼音简写</th>
                        <th>英文名称</th>
                        <th>商品类型</th>
                        <th>业务类型</th>
                        <th>商品单价</th>
                        <th>erp商品名称</th>
                        <th>创建时间</th>
                        <th>更新时间</th>
                        <th>状态</th>
                    </tr>
                    </thead>
                    <tbody class="limiting" :style="{'border-bottom':merchandise.length<1?'0px':'',
                'width':merchandise.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}">
                    <tr v-for="(item,i) in merchandise" :key="item.id" class="drag-list" draggable="true"
                        @dragstart="dragstart(item)" @dragenter="dragenter(item)" @dragend="dragend(item)">
                        <td :style="{'border-left':item.d==1?'1px solid #16D52B':'1px solid #f5f5f5','color':item.s=='无效'?'#595959':''}">
                            <el-checkbox-group v-model="checkedCities" @change="handleCheckedCitiesChange">
                                <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                            </el-checkbox-group>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <ellipsis-tooltip :text="item.np || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <ellipsis-tooltip :text="item.ne || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.pt}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.bt || '-----'}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <ellipsis-tooltip class="money" :text="item.p || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">
                            <ellipsis-tooltip :text="item.en || '-----'"></ellipsis-tooltip>
                        </td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                        <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                    </tr>
                    </tbody>
                </table>
                <div class="drag-list" v-if="merchandise.length<1">
                    <td class="nodata">
                        <img src="../../../../assets/img/wu.png" alt="">
                        <div class="hint">暂无数据</div>
                    </td>
                </div>
            </div>
            <div class="between" v-if="!classify.stairSecond[classify.stairfl].ss">
                <img src="../../../../assets/img/wu.png" alt="">
                <div class="period">
                    请先创建该分类下的二级分类
                </div>
            </div>
        </div>
        <div class="between" v-if="classify.stairSecond.length == 0">
            <img src="../../../../assets/img/wu.png" alt="">
            <div class="period">
                请先创建一级分类
            </div>
        </div>

        <!-- 新增单品 -->
        <div class="dialogPrinter" v-if="QuantityProduction">
            <el-dialog :title="singlecommodities?'新增单品':'编辑单品'" :visible.sync="QuantityProduction"
                       @close="QuantityProduction = false" :close-on-click-modal="false">
                <!-- <div class="biaot">基本属性</div> -->
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>分类：
                            </div>
                            <div class="controlling" v-if="classify.stairSecond[classify.stairfl]">
                                {{classify.stairSecond[classify.stairfl].n}} <i class="el-icon-arrow-right"></i>
                                {{classify.stairSecond[classify.stairfl].ss[classify.Secondfl].n}}
                            </div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>名称：
                            </div>
                            <el-input v-model="newmerchandise.name" placeholder="请输入名称" class="controlling"
                                      ref="xidhf"/>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>拼音简写：
                            </div>
                            <div style="color:#40404e;line-height: 40px;" class="controlling">
                                {{newmerchandise.phoneticize}}
                            </div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>英文名：
                            </div>
                            <el-input v-model="newmerchandise.English" placeholder="请输入英文名" class="controlling"/>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>类型：
                            </div>
                            <el-select v-model="newmerchandise.SKUtype" placeholder="请选择类型" class="controlling">
                                <el-option label="普通" value="1"></el-option>
                                <el-option label="特饮" value="3"></el-option>
                                <el-option label="小费" value="4"></el-option>
                                <el-option label="赔偿" value="5"></el-option>
                                <el-option label="联营" value="6"></el-option>
                            </el-select>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>单价：
                            </div>
                            <el-input v-show="!newmerchandise.marketprices" v-model="newmerchandise.price"
                                      placeholder="请输入单价" class="controlling"/>
                            <div v-show="newmerchandise.marketprices" class="controlling">{{newmerchandise.price}}</div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>营业类型：
                            </div>
                            <el-select v-model="newmerchandise.businesstype" placeholder="请选择营业类型" class="controlling"
                                       :disabled="newmerchandise.forbidden">
                                <el-option label="主营" value="1"></el-option>
                                <el-option label="非主营" value="2"></el-option>
                            </el-select>
                        </div>
                    </div>
                    <div class="compatibil" v-show="newmerchandise.Inventorygoods">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>存货商品：
                            </div>
                            <div class="controlling" v-show="newmerchandise.inventory.id">
                                {{newmerchandise.inventory.n}}
                            </div>
                            <el-button type="primary" v-show="newmerchandise.inventory.id" @click="binding">去修改
                            </el-button>
                            <el-button type="primary" v-show="!newmerchandise.inventory.id" @click="binding">去绑定
                            </el-button>
                        </div>
                    </div>
                </el-form>
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility">
                            <table class="extend-unit">
                                <thead class="mmodity">
                                <tr>
                                    <th>
                                        <el-checkbox :indeterminate="nature_isIndeterminate" v-model="nature_checkAll"
                                                     @change="nature_handleCheckAllChange">行号
                                        </el-checkbox>
                                    </th>
                                    <th>区域名称</th>
                                    <th>出品库</th>
                                    <th>区域状态</th>
                                </tr>
                                </thead>
                                <tbody class="limiting">
                                <tr v-for="(item,i) in regions" :key="i" class="drag-list">
                                    <td>
                                        <el-checkbox-group v-model="nature_checkedCities"
                                                           @change="nature_handleCheckedCitiesChange">
                                            <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                        </el-checkbox-group>
                                    </td>
                                    <td :style="{'color':item.s==1?'':'#595959'}">{{item.n}}</td>
                                    <td>
                                        <el-select v-model="regions[i].fmk" placeholder="请选择出品库">
                                            <el-option v-for="each in regions[i].mklibs" :key="each.id" :label="each.n"
                                                       :value="each.id"></el-option>
                                        </el-select>
                                    </td>
                                    <td :style="{'color':item.s==1?'':'#595959'}">{{item.s == 1?'有效':'无效'}}</td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="QuantityProduction = false">取消</el-button>
                    <el-button type="primary" v-show="singlecommodities" @click="NewPayChannel">确认</el-button>
                    <el-button type="primary" v-show="!singlecommodities" @click="savecommodity">保存</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 绑定erp商品 -->
        <div class="user-defined" v-show="ERPcommodity">
            <el-dialog title="绑定erp商品" @close="ERPcommodity = false" :visible.sync="ERPcommodity"
                       :close-on-click-modal="false">
                <div class="in_sum-rkrq">
                    <div class="rkrq">
                        <span>商品：</span>
                        <el-cascader
                                clearable
                                :options="dept_items"
                                :props="optionProps"
                                v-model="dept_code"
                                :show-all-levels="false"
                                popper-class='liebdwd'
                                ref="cascaderRef">
                        </el-cascader>
                    </div>
                    <div class="rkrq">
                        <el-input v-model="erp_prds.name" placeholder="请输入erp商品名称 模糊查询"></el-input>
                    </div>
                    <div class="rkrq">
                        <el-button type="primary" @click="prderp_prds">查询</el-button>
                    </div>
                </div>
                <div style="display: inline-block;width: 602px; ">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>erp商品名称</th>
                            <th>erp商品分类树描述</th>
                            <th>单位</th>
                            <th>状态</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in erps_prdss" :key="i" class="drag-list" draggable="true">
                            <td :style="{'border-left':'1px solid #f5f5f5','color':item.s=='无效'?'#595959':''}">
                                <el-checkbox-group v-model="checkedCitispes">
                                    <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                                </el-checkbox-group>
                                <!-- <el-radio v-model="checkedCitispes" :label="item.c">{{i+1}}&emsp;&ensp;</el-radio> -->
                            </td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cp}}</td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.un}}</td>
                            <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                        </tr>
                        <tr class="drag-list" v-if="erps_prdss.length<1">
                            <td class="nodata">
                                <img v-show="controlpicture ==1" src="../../../../assets/img/wu.png" alt="">
                                <img v-show="controlpicture ==2" src="../../../../assets/img/空-请检索.png" alt="">
                                <img v-show="controlpicture ==3" src="../../../../assets/img/加载中.png" alt="">
                                <div v-show="controlpicture ==1" class="hint">暂无数据</div>
                                <div v-show="controlpicture ==2" class="hint">空-请检索</div>
                                <div v-show="controlpicture ==3" class="hint">加载中...</div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                    <div class="Pagination">
                        <el-pagination
                                background
                                layout="prev, pager, next"
                                @current-change="handleCurrentChange"
                                :page-size="erp_prds.page_size"
                                :total="erp_prds.rowcnt">
                        </el-pagination>
                    </div>
                </div>


                <span slot="footer" class="dialog-footer">
                  <el-button @click="ERPcommodity = false">取消</el-button>
                  <el-button type="primary" @click="bindingERp">绑定</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 新增套餐 -->
        <div class="dialogsetmeal" v-if="newsetmeals">
            <el-dialog :title="singlecommodities?'新增套餐':'编辑套餐'" ref="rollbott" :visible.sync="newsetmeals"
                       @close="newsetmeals = false" :close-on-click-modal="false">
                <!-- <div class="biaot">基本属性</div> -->
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>分类：
                            </div>
                            <div class="controlling" v-if="classify.stairSecond[classify.stairfl]">
                                {{classify.stairSecond[classify.stairfl].n}} <i class="el-icon-arrow-right"></i>
                                {{classify.stairSecond[classify.stairfl].ss[classify.Secondfl].n || ''}}
                            </div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>名称：
                            </div>
                            <el-input v-model="setmeals.name" placeholder="请输入名称" class="controlling" ref="xidhf"/>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>拼音简写：
                            </div>
                            <div style="color:#40404e;line-height: 40px;" class="controlling">{{setmeals.phoneticize}}
                            </div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>英文名：
                            </div>
                            <el-input v-model="setmeals.English" placeholder="英文名" class="controlling"/>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>单价：
                            </div>
                            <el-input v-model="setmeals.price" placeholder="单价" class="controlling"/>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>固定单品：
                            </div>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <table class="extend-unit">
                                <thead class="mmodity">
                                <tr>
                                    <th style="border-left: 1px solid #f5f5f5;background-color: #3C2D2F;">行号</th>
                                    <th style="background-color: #3C2D2F;">单品名称</th>
                                    <th style="background-color: #3C2D2F;">分类</th>
                                    <th style="background-color: #3C2D2F;">单价</th>
                                    <th style="background-color: #3C2D2F;" class="tbdgf">
                                        <span>数量</span>
                                        <el-tooltip class="item" effect="light" content="数量不填，默认为1" placement="top">
                                            <img src="../../../../assets/img/问号.png" alt="">
                                        </el-tooltip>
                                    </th>
                                    <th style="background-color: #3C2D2F;">存货商品名</th>
                                    <th style="background-color: #3C2D2F;">类型</th>
                                    <th style="background-color: #3C2D2F;">营业类型</th>
                                    <th style="background-color: #3C2D2F;">状态</th>
                                    <th style="background-color: #3C2D2F;">操作</th>
                                </tr>
                                </thead>
                                <tbody class="limiting">
                                <tr v-for="(item,i) in setmeallist" :key="i" class="drag-list">
                                    <td :style="{'color':item.s=='2'?'#595959':'','border-left':'1px solid #f5f5f5'}">
                                        {{i+1}}
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">
                                        <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.on}} <i
                                            class="el-icon-arrow-right"></i> {{item.tn}}
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">
                                        <div class="money">{{item.p}}</div>
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">
                                        <el-input v-model="item.pc" placeholder="请输入数量" class="alignment"/>
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">
                                        <ellipsis-tooltip :text="item.en || '-----'"></ellipsis-tooltip>
                                    </td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                                    <td style="color: #438dfd" @click="dpdelete(i)">删除</td>
                                </tr>
                                <tr class="drag-list" v-if="setmeallist.length<1">
                                    <td class="nodata" colspan="10" style="border-left: 1px solid #f5f5f5;">
                                        <img src="../../../../assets/img/wu.png" alt="">
                                        <div class="hint">暂无数据</div>
                                    </td>
                                </tr>
                                <tr class="drag-list" @click="additional(true)">
                                    <td class="Theewitem" style="border-left: 1px solid #f5f5f5;">
                                        <div>＋</div>
                                        <div>添加单品</div>
                                    </td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>可替换：
                            </div>
                        </div>
                    </div>
                    <div class="keorganize" :class="{'highlight' : item.deletejudge}" v-for="(item,j) in substitute"
                         :key="j">
                        <div class="grouphandle">
                            <div class="choice">
                                {{item.items.length}}&ensp;选 &ensp;
                                <el-input v-model="item.sel_cnt" placeholder="" style="width:80px; font-size: 20px;"/>
                                <el-tooltip class="hintimg" effect="light" placement="top">
                                    <div slot="content">
                                        N 选 M, 表示客户下单该套餐, 可以从该组N个选项中, 随意选出M项。
                                        <br/>
                                        注意M是可以大于N的。
                                        <br/>
                                        举例: 如果选项是 红茶2瓶, 绿茶2瓶. 配置的选项是 2 选 3。
                                        <br/>
                                        那么客户下单套餐时, 可以选 1份红茶2瓶, 2份绿茶2瓶。
                                        <br/>
                                    </div>
                                    <img src="../../../../assets/img/问号.png" alt="">
                                </el-tooltip>
                            </div>
                            <div v-show="!item.deletejudge" class="deletereplace" @click="item.deletejudge = true">
                                －删除该替换组
                            </div>
                            <div v-show="item.deletejudge" style="display: flex;">
                                <div class="deletereplace" @click="item.deletejudge = false">取消</div>
                                <div class="reddeletereplace" @click="deletereplace(j)">删除</div>
                            </div>
                        </div>
                        <table class="extend-unit">
                            <thead class="mmodity">
                            <tr>
                                <th style="border-left: 1px solid #f5f5f5;">行号</th>
                                <th>单品名称</th>
                                <th>分类</th>
                                <th>单价</th>
                                <th class="tbdgf">
                                    <span>数量</span>
                                    <el-tooltip class="item" effect="light" content="数量不填，默认为1" placement="top">
                                        <img src="../../../../assets/img/问号.png" alt="">
                                    </el-tooltip>
                                </th>
                                <th>存货商品名</th>
                                <th>类型</th>
                                <th>营业类型</th>
                                <th>状态</th>
                                <th>操作</th>
                            </tr>
                            </thead>
                            <tbody class="limiting">
                            <tr v-for="(item,i) in item.items" :key="i" class="drag-list">
                                <td :style="{'color':item.s=='2'?'#595959':'','border-left':'1px solid #f5f5f5'}">
                                    {{i+1}}
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">
                                    <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">{{item.on}} <i
                                        class="el-icon-arrow-right"></i> {{item.tn}}
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">
                                    <div class="money">{{item.p}}</div>
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">
                                    <el-input v-model="item.pc" placeholder="请输入数量" class="alignment"/>
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">
                                    <ellipsis-tooltip :text="item.en || '-----'"></ellipsis-tooltip>
                                </td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                                <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                                <td style="color: #438dfd" @click="dpdeletereplace(j,i)">删除</td>
                            </tr>
                            <tr class="drag-list" v-if="item.items.length<1">
                                <td class="nodata" colspan="10" style="border-left: 1px solid #f5f5f5;">
                                    <img src="../../../../assets/img/wu.png" alt="">
                                    <div class="hint">暂无数据</div>
                                </td>
                            </tr>
                            <tr class="drag-list" @click="additional(false,j)">
                                <td class="Theewitem" style="border-left: 1px solid #f5f5f5;">
                                    <div>＋</div>
                                    <div>添加单品</div>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="setaddmeal" @click="addtitutiongroups">
                        <div class="select">
                            3&ensp;选 &ensp;
                            <div>9999</div>
                        </div>
                        <table class="extend-unit">
                            <thead class="mmodity">
                            <tr>
                                <th style="border-left: 1px solid #f5f5f5;">行号</th>
                                <th>单品名称</th>
                                <th>分类</th>
                                <th>单价</th>
                                <th class="tbdgf">
                                    <span>数量</span>
                                </th>
                                <th>存货商品名</th>
                                <th>类型</th>
                                <th>营业类型</th>
                                <th>状态</th>
                                <th>操作</th>
                            </tr>
                            </thead>
                        </table>
                        <div class="taddmeal"><span>＋</span> 新增替换组</div>
                    </div>
                    <div class="compatibil">
                        <div class="compatibility">
                            <table class="extend-unis">
                                <thead class="mmodity">
                                <tr>
                                    <th>
                                        <el-checkbox :indeterminate="nature_isIndeterminate" v-model="nature_checkAll"
                                                     @change="nature_handleCheckAllChange">行号
                                        </el-checkbox>
                                    </th>
                                    <th>区域名称</th>
                                    <th>区域状态</th>
                                </tr>
                                </thead>
                                <tbody class="limiting">
                                <tr v-for="(item,i) in regions" :key="i" class="drag-list">
                                    <td>
                                        <el-checkbox-group v-model="nature_checkedCities"
                                                           @change="nature_handleCheckedCitiesChange">
                                            <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                        </el-checkbox-group>
                                    </td>
                                    <td :style="{'color':item.s==1?'':'#595959'}">{{item.n}}</td>
                                    <td :style="{'color':item.s==1?'':'#595959'}">{{item.s == 1?'有效':'无效'}}</td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </el-form>
                <span slot="footer" class="dialog-footer">
                    <el-button @click="newsetmeals = false">取消</el-button>
                    <el-button type="primary" v-show="singlecommodities" @click="addsetmeal">确认</el-button>
                    <el-button type="primary" v-show="!singlecommodities" @click="saveitpackage">保存</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 新增套餐单品 -->
        <div class="newdefined" v-show="newexhibits">
            <el-dialog title="新增单品" @close="newexhibits = false" :visible.sync="newexhibits"
                       :close-on-click-modal="false">
                <div class="in_sum-rkrq">
                    <div class="rkrq">
                        <span>商品：</span>
                        <el-cascader
                                clearable
                                :options="dcommoditytems"
                                :props="optionProp"
                                v-model="commoditycode"
                                popper-class='liebdwd'
                                ref="cascaderRef">
                        </el-cascader>
                    </div>
                    <div class="rkrq">
                        <el-input v-model="get_set_items.name" placeholder="请输入商品名称 模糊查询"></el-input>
                    </div>
                    <div class="rkrq">
                        <el-button type="primary" @click="gett_wwite">查询</el-button>
                    </div>
                </div>
                <div style="display: inline-block;width: 602px; ">
                    <table class="zhuixiaoi">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>单品名称</th>
                            <th>分类</th>
                            <th>单价</th>
                            <!-- <th>数量</th> -->
                            <th>存货商品名</th>
                            <th>类型</th>
                            <th>营业类型</th>
                            <th>状态</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in ImportDatas" :key="i" class="drag-list" draggable="true">
                            <td :style="{'border-left':'1px solid #f5f5f5','color':item.s=='2'?'#595959':''}">
                                <el-checkbox-group v-model="checkedCitispes" :disabled="item.control">
                                    <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                </el-checkbox-group>
                            </td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.n}}</td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.on}} <i
                                    class="el-icon-arrow-right"></i> {{item.tn}}
                            </td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">
                                <div class="money">{{item.p}}</div>
                            </td>
                            <!-- <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pc}}</td> -->
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.en || '-----'}}</td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                            <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                        </tr>
                        <tr class="drag-list" v-if="ImportDatas.length<1">
                            <td class="nodata">
                                <img v-show="contcture ==1" src="../../../../assets/img/wu.png" alt="">
                                <img v-show="contcture ==2" src="../../../../assets/img/空-请检索.png" alt="">
                                <img v-show="contcture ==3" src="../../../../assets/img/加载中.png" alt="">
                                <div v-show="contcture ==1" class="hint">暂无数据</div>
                                <div v-show="contcture ==2" class="hint">空-请检索</div>
                                <div v-show="contcture ==3" class="hint">加载中...</div>
                            </td>
                        </tr>
                        <infinite-loading
                                ref="infiniteLoading"
                                v-if="ImportDatas.length>0"
                                @infinite="infiniteHandler"
                                force-use-infinite-wrapper=".el-table__body-wrapper">
                            <div class="loadmore" slot="spinner">加载中...</div>
                            <div class="loadmore" slot="no-more">没有更多数据</div>
                            <div class="loadmore" slot="no-results">没有更多数据</div>
                        </infinite-loading>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="newexhibits = false">取消</el-button>
                  <el-button v-show="estimategdthz" type="primary" @click="setmealewproduct">新增</el-button>
                  <el-button v-show="!estimategdthz" type="primary" @click="addchangeof">新增</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 是否强制创建套餐 -->
        <div class="deletealternative" v-show="deletealtative">
            <el-dialog title="新增套餐" @close="deletealtative = false" :visible.sync="deletealtative"
                       :close-on-click-modal="false">
                <div class="del">
                    该套餐配置明细中, 存在无效单品。<br/>
                    如果强制新增, 该套餐会自动设置为<span>无效</span>状态（将来需<span>手动</span>设置该套餐为有效状态）, 是否强制新增该套餐?
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button @click="deletealtative = false">取消</el-button>
                  <el-button type="primary" @click="compellent">强制新增</el-button>
                </span>
            </el-dialog>
        </div>

        <!-- 创建套餐可点区域问题 -->
        <div class="Seternewdefed" v-show="Seterrortxsf">
            <el-dialog title="新增套餐错误" @close="Seterrortxsf = false" :visible.sync="Seterrortxsf"
                       :close-on-click-modal="false">
                <div class="ewdefed">{{Seterrorthree.msg}}</div>
                <div style="display: inline-block;">
                    <table class="zhuixaoise">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>单品名称</th>
                            <th>分类</th>
                            <th>问题区域</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in Seterrorthree.data" :key="i" class="drag-list">
                            <td :style="{'border-left':'1px solid #f5f5f5'}">
                                {{i+1}}
                            </td>
                            <td>{{item.n}}</td>
                            <td>{{item.on}} <i class="el-icon-arrow-right"></i> {{item.tn}}</td>
                            <td>
                                <div class="divbigesd" v-for="(ite,j) in item.r" :key="j">
                                    <div class="data">
                                        {{ite}}
                                    </div>
                                    <div v-if="j+1 != item.r.length" class="xian"></div>
                                </div>
                            </td>
                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button type="primary" @click="Seterrortxsf = false">确定</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 有效套餐使用到了置为无效的商品 -->
        <div class="invalidefed" v-show="invalidive">
            <el-dialog :title="scwxvalidive?'置为无效错误':'删除发生错误'" @close="invalidive = false" :visible.sync="invalidive"
                       :close-on-click-modal="false">
                <div class="ewdefed">{{invalidree.msg}}</div>
                <div style="display: inline-block;">
                    <table class="zhuixaoise">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>套餐名称</th>
                            <th>套餐分类</th>
                            <th>被依赖商品</th>
                            <th>商品分类</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in invalidree.data" :key="i" class="drag-list" draggable="true">
                            <td :style="{'border-left':'1px solid #f5f5f5'}">
                                {{i+1}}
                            </td>
                            <td>{{item.sn}}</td>
                            <td>{{item.so}} <i class="el-icon-arrow-right"></i> {{item.st}}</td>
                            <td>{{item.pn}}</td>
                            <td>{{item.po}} <i class="el-icon-arrow-right"></i> {{item.pt}}</td>

                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button type="primary" @click="invalidive = false">确定</el-button>
                </span>
            </el-dialog>
        </div>
        <!-- 设置为有效的一级分类下有效单品对应的出品库异常 -->
        <div class="roductibrive" v-show="roductibrive">
            <el-dialog title="置为有效错误" @close="roductibrive = false" :visible.sync="roductibrive"
                       :close-on-click-modal="false">
                <div class="ewdefed">{{Productibrary.msg}}</div>
                <div style="display: inline-block;">
                    <table class="zhuixaoise" v-show="pandsansi">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>单品名称</th>
                            <th>分类</th>
                            <th>区域</th>
                            <th>出品库</th>
                            <th>问题描述</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in Productibrary.data" :key="i" class="drag-list" draggable="true">
                            <td :style="{'border-left':'1px solid #f5f5f5'}">
                                {{i+1}}
                            </td>
                            <td>{{item.pn}}</td>
                            <td>{{item.pon}} <i class="el-icon-arrow-right"></i> {{item.ptn}}</td>
                            <td>{{item.rn}}</td>
                            <td>{{item.mn}}</td>
                            <td>
                                <ellipsis-tooltip :text="item.c || '-----'"></ellipsis-tooltip>
                            </td>

                        </tr>
                        </tbody>
                    </table>
                    <table class="zhuiisese" v-show="!pandsansi">
                        <thead class="mmodity">
                        <tr>
                            <th style="border-left:1px solid #f5f5f5">行号</th>
                            <th>套餐名称</th>
                            <th>套餐分类</th>
                            <th>单品名称</th>
                            <th>单品分类</th>
                        </tr>
                        </thead>
                        <tbody class="limiting">
                        <tr v-for="(item,i) in Productibrary.data" :key="i" class="drag-list" draggable="true">
                            <td :style="{'border-left':'1px solid #f5f5f5'}">
                                {{i+1}}
                            </td>
                            <td>{{item.sn}}</td>
                            <td>{{item.son}} <i class="el-icon-arrow-right"></i> {{item.stn}}</td>
                            <td>{{item.pn}}</td>
                            <td>{{item.pon}} <i class="el-icon-arrow-right"></i> {{item.ptn}}</td>

                        </tr>
                        </tbody>
                    </table>
                </div>
                <span slot="footer" class="dialog-footer">
                  <el-button type="primary" @click="roductibrive = false">确定</el-button>
                </span>
            </el-dialog>
        </div>

    </div>
</template>
<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import IconButton from '@/components/IconButton.vue'//根据路径导入组件
import InfiniteLoading from 'vue-infinite-loading';
export default {
  data() {
    return {
      oldItem: '',//记录初始信息
      newItem: '',// 记录过程中信息

      ERPcommodity: false,//控制ERP商品弹窗
      dept_items: [],//ERP商品信息
      optionProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        checkStrictly: true,
        expandTrigger: 'hover'
      },//规则
      erp_prds: {
        page_num: 1,//第几页
        page_size: 6,//每页行数
        is_init: 1,//页面初始化
        erp_cate_code: "",//erp商品分类编码
        name: '',//erp商品名称 模糊查询
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
      },
      dept_code: [],//商品分类树
      erps_prdss: [],//erp商品数据
      checkedCitispes: [],//已选择内容

      List: [],//全部内容
      checkAll: false,//全部选中触发
      checkedCities: [],//已选择内容
      isIndeterminate: false,//全选或者全不选

      classify: {
        stairSecond: [],//一级二级全部内容分类
        stairfl: 0,//一级分类
        Secondfl: 0,//二级分类
      },//分类
      mklibs: [],//出品库
      regions: [],//区域
      nature_isIndeterminate: false,// 区域全选或者全不选
      nature_checkAll: false,//区域全部选中触发
      nature_checkedCities: [],//区域已选择内容

      pdddymy: false,//判断有没有二级分类
      merchandise: [],//物料
      QuantityProduction: false,//控制新增物料的打开关闭
      newmerchandise: {
        name: '',//物料名称
        phoneticize: '',//拼音
        English: '',//英文名
        price: '',//单价
        marketprices: false,//根据商品类型改变
        SKUtype: '',//商品类型
        businesstype: '',//营业类型
        forbidden: false,// 禁用
        inventory: {},//存货商品
        Inventorygoods: true,//存货商品是否显示
      },//新建物料
      singlecommodities: true,// 判断单品是编辑还是新增

      setmeals: {
        name: '',//物料名称
        phoneticize: '',//拼音
        English: '',//英文名
        price: '',//单价
        one_cate_id: 0,//一级id
        two_cate_id: 0,//二级id
        is_force: 2,//是否强制添加, 1 强制添加 2  普通模式添加
      },//套餐
      newsetmeals: false,//控制新增套餐
      setmeallist: [],//套餐列表
      newexhibits: false,//控制新增单品
      get_set_items: {
        name: '',
        page_num: 1,//第几页
        page_size: 6,//每页行数
        is_init: 1,
      },
      ImportDatas: [],//无限加载列表内容
      dcommoditytems: [],//单品信息
      optionProp: {
        value: 'id',
        label: 'n',
        children: 'ss',
        checkStrictly: true,
        expandTrigger: 'hover'
      },//规则
      commoditycode: [],//单品分类树

      substitute: [],//替换组
      estimategdthz: true,//判断是固定单品还是替换组添加
      Whichoneadd: 0,//判断添加到哪里
      substijige: 0,//删除第几个替换组
      deletealtative: false,//判断是否强制创建套餐
      Seterrorthree: {},//套餐错误3返回列表
      Seterrortxsf: false,//判断套餐错误3列表是否显示

      invalidree: {},//置为无效时错误2返回列表
      invalidive: false,//判断是否显示错误列表
      scwxvalidive: true,// 判断是删除还是置为无效文案

      Productibrary: {},//置为有效时错误3 4返回列表
      roductibrive: false,//判断是否显示错误列表
      pandsansi: true,//判断是错误3还是4

      controlpicture: '2',// erp搜索商品
      contcture: '2',//搜索单品
      windowWidt: document.documentElement.clientWidth,  //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight,   //实时屏幕高度
      MaxHeight: 0,//滚动高度
      MaxNumber: 0//最大个数
    }
  },
  mounted(){
    // this.$loading(options)
    // console.log(this.$loading(options));
    this.demand();
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
  components: {
    EllipsisTooltip,
    IconButton,
    InfiniteLoading
  },
  methods: {
    // 滚动最大高度
    RollMaxHeight(i){
      var s = i - 48 - 60 - 55 - 37 - 170
      this.MaxHeight = s
      this.MaxNumber = Math.floor(s / 37)
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 请求数据
    demand(){
      this.$api.BMS.Prd.requestprdass_items().then(res => {
        if (res.code == 1) {
          console.log(res.data.regions);
          this.classify.stairSecond = res.data.cates || []
          if (res.data.regions) {
            for (const key in res.data.regions) {
              res.data.regions[key].fmk = this.classify.stairSecond[this.classify.stairfl].fmk
              if (res.data.regions[key].s == 1) {
                res.data.regions[key].mklibs = []
                for (const iterator of res.data.mklibs || []) {
                  if (iterator.s == 1) {
                    res.data.regions[key].mklibs.push(iterator)
                  }
                }
              } else {
                res.data.regions[key].mklibs = res.data.mklibs || []
              }
            }
          }
          this.regions = res.data.regions || []
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 记录初始信息
    dragstart(item) {
      this.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.newItem = item;
    },
    // 做最终操作
    dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.merchandise.indexOf(this.oldItem);
        let newIndex = this.merchandise.indexOf(this.newItem);
        console.log(oldIndex);
        console.log(newIndex);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }
        this.$api.BMS.Prd.requestprdmove_dsp({
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({showClose: true, message: "更改位置成功", type: 'success', duration: 1000})
            let newList = [...this.merchandise]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.merchandise = [...newList];
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 刷新物料
    refresh(id){
      this.$api.BMS.Prd.requestprdlist({
        id
      }).then(res => {
        console.log(res);
        this.merchandise = res.data || []
      })
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      console.log(this.merchandise);
      console.log(val);
      if (val) {
        // console.log(this.merchandise);
        this.checkedCities = []
        for (const key in this.merchandise) {
          this.checkedCities.push(this.merchandise[key].id)
        }
      } else {
        this.checkedCities = []
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.merchandise.length;
      this.isIndeterminate = checkedCount > 0 && checkedCount < this.merchandise.length;
      // console.log(this.checkedCities);
    },
    // 打开新增物料
    VolumeProduction(){
      if (this.pdddymy) {
        // console.log(this.classify.stairSecond[this.classify.stairfl].fmk);
        this.QuantityProduction = true


        this.newmerchandise.name = ''
        this.newmerchandise.phoneticize = ''
        this.newmerchandise.English = ''
        this.newmerchandise.price = ''
        this.newmerchandise.SKUtype = ''
        this.newmerchandise.businesstype = ''
        this.newmerchandise.forbidden = false
        this.newmerchandise.marketprices = false
        this.newmerchandise.inventory = {}

        this.singlecommodities = true

        this.nature_isIndeterminate = false
        this.nature_checkAll = false
        this.nature_checkedCities = []

        // console.log(this.regions);
        if (this.nature_checkedCities.length > 0) {
          this.nature_checkAll = true
        }
        this.$nextTick(() => {  //次要代码
          this.$refs.xidhf.focus();
          //   console.log(this.$refs.xidhf);
        })


        // this.$api.BMS.Prd.requestprdass_items().then(res=>{
        //     if(res.code == 1){
        //         console.log(res.data.regions);
        //         this.classify.stairSecond = res.data.cates || []
        //         this.regions =  res.data.regions || []
        //         if(res.data.regions){
        //             for (const key in res.data.regions) {
        //                 res.data.regions[key].fmk = this.classify.stairSecond[this.classify.stairfl].fmk
        //                 if(res.data.regions[key].s == 1){
        //                     res.data.regions[key].mklibs = []
        //                     for (const iterator of res.data.mklibs || []) {
        //                         if(iterator.s == 1){
        //                             res.data.regions[key].mklibs.push(iterator)
        //                         }
        //                     }
        //                 }else{
        //                     res.data.regions[key].mklibs = res.data.mklibs || []
        //                 }
        //             }
        //         }
        //     }else{
        //         this.$message.warning(res.msg)
        //     }
        // })
        for (const key in this.regions) {
          if (this.regions[key].s == 1) {
            this.nature_checkedCities.push(this.regions[key].id)
          }

        }

      } else {
        this.$message({showClose: true, message: "没有二级分类，请先创建二级分类", type: 'warning',})
      }
    },
    // 物料单位控制全选或者全不选
    nature_handleCheckAllChange(val) {
      if (val) {
        this.nature_checkedCities = []
        for (const key in this.regions) {
          this.nature_checkedCities.push(this.regions[key].id)
        }
      } else {
        this.nature_checkedCities = []
      }
      this.nature_isIndeterminate = false;
    },
    // 物料单位控制单个选中
    nature_handleCheckedCitiesChange(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.nature_checkAll = checkedCount === this.regions.length;
      this.nature_isIndeterminate = checkedCount > 0 && checkedCount < this.regions.length;
    },
    // 打开绑定
    binding(){
      this.controlpicture = '2'
      this.dept_code = []//商品分类树
      this.erps_prdss = []//erp商品数据
      this.erp_prds = {
        page_num: 1,//第几页
        page_size: 6,//每页行数
        is_init: 1,//页面初始化
        erp_cate_code: "",//erp商品分类编码
        name: '',//erp商品名称 模糊查询
        pagecnt: 1,//总页数
        rowcnt: 1,//总行数
      }

      this.ERPcommodity = true
      // this.prderp_prds()
    },
    // 读取erp商品
    prderp_prds(){
      this.controlpicture = '3'
      this.erps_prdss = []
      setTimeout(() => {
        this.$api.BMS.Prd.requestprderp_prds({
          page_num: this.erp_prds.page_num,
          page_size: this.erp_prds.page_size,
          is_init: this.erp_prds.is_init,
          erp_cate_id: this.erp_prds.erp_cate_code,
          name: this.erp_prds.name,
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            if (res.data.erp_prds == null) {
              this.controlpicture = '1'
            }
            this.dept_items = res.data.erp_cates || []
            this.erps_prdss = res.data.erp_prds || []
            this.page_num = res.data.page_num
            this.pagecnt = res.data.page_cnt
            this.rowcnt = res.data.row_cnt
          } else {
            this.$message.warning(res.msg)
          }
        })
      }, 1000)
    },
    // 绑定
    bindingERp(){
      console.log(this.checkedCitispes);
      console.log(this.erps_prdss);
      if (this.checkedCitispes.length == 1) {
        for (const key in this.erps_prdss) {
          if (this.erps_prdss[key].id == this.checkedCitispes[0]) {
            console.log(123);
            this.newmerchandise.inventory = this.erps_prdss[key]
          }
        }
        this.ERPcommodity = false
      } else {
        this.$message.warning('请选中一个进行绑定')
      }

    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.erp_prds.page_num = val
      this.prderp_prds()
    },
    // 新增商品
    NewPayChannel(){
      // console.log(this.newmerchandise.price=='时价'?'0':this.newmerchandise.price);
      var s = []
      var w = []
      for (const key in this.regions) {
        for (const ke in this.nature_checkedCities) {
          if (this.regions[key].id == this.nature_checkedCities[ke]) {
            s.push(this.regions[key].id)
            w.push(this.regions[key].fmk)
          }
        }
      }
      this.$api.BMS.Prd.requestprdnew({
        name: this.newmerchandise.name,
        one_cate_id: this.classify.stairSecond[this.classify.stairfl].id,
        two_cate_id: this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id,
        name_eng: this.newmerchandise.English,
        name_py: this.newmerchandise.phoneticize,
        name: this.newmerchandise.name,
        price: this.newmerchandise.price == '时价' ? '0' : this.newmerchandise.price,
        prd_type: Number(this.newmerchandise.SKUtype),
        biz_type: Number(this.newmerchandise.businesstype),
        erp_prd_id: this.newmerchandise.inventory.id,
        regions: s,
        mklibs: w,
      }).then(res => {
        console.log(res);
        if (res.code == 1 || res.code == 6) {
          this.QuantityProduction = false
          // console.log(res);
          this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          if(res.msg === '') {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: 'warning'
            })
          }
        } else {
          this.$message({message: res.msg, type: 'error'})
        }
      })
    },
    // 判断打开单品还是套餐编辑
    staircompile(){
      if (this.checkedCities.length == 1) {
        for (const key in this.merchandise) {
          if (this.checkedCities[0] == this.merchandise[key].id) {
            console.log(this.merchandise[key].pt);
            if (this.merchandise[key].pt == '套餐') {
              this.Editpackage()
            } else {
              this.Commoditiesditor()
            }
          }
        }
      } else {
        this.$message({
          message: '请选择一个进行编辑',
          type: 'warning',
        })
      }
    },
    // 打开单品编辑
    Commoditiesditor(){
      this.$api.BMS.Prd.requestprdget({id: this.checkedCities[0]}).then(res => {
        console.log(11, res);
        this.singlecommodities = false
        this.newmerchandise = {
          name: res.data.prd.name,
          phoneticize: res.data.prd.name_py,
          English: res.data.prd.name_eng,
          businesstype: res.data.prd.biz_type + '',
          inventory: {
            id: res.data.prd.erp_prd_id,
            n: res.data.prd.erp_prd_name
          },
          marketprices: this.newmerchandise.marketprices,
          forbidden: this.newmerchandise.forbidden,
          Inventorygoods: this.newmerchandise.Inventorygoods,
          price: res.data.prd.price + '',
          SKUtype: res.data.prd.prd_type + '',
        }
        this.QuantityProduction = true
        for (const key in this.regions) {
          this.nature_checkedCities = []
          for (const iterator of res.data.region_prds) {
            this.nature_checkedCities.push(iterator.rid)
            if (this.regions[key].id == res.data.region_prds.rid) {
              this.regions[key].fmk = res.data.region_prds.mid
            }
          }
        }
        if (this.regions.length == res.data.region_prds.length) {
          this.nature_checkAll = true
        } else if (this.regions.length > res.data.region_prds.length) {
          this.nature_isIndeterminate = true
        }


      })
    },
    // 保存编辑商品
    savecommodity(){
      var s = []
      var w = []
      for (const key in this.regions) {
        for (const ke in this.nature_checkedCities) {
          if (this.regions[key].id == this.nature_checkedCities[ke]) {
            s.push(this.regions[key].id)
            w.push(this.regions[key].fmk)
          }
        }
      }
      if (this.newmerchandise.SKUtype != 1 && this.newmerchandise.SKUtype != 3) {
        this.newmerchandise.inventory = {}
      }
      this.$api.BMS.Prd.requestprdsave({
        id: this.checkedCities[0],
        name: this.newmerchandise.name,
        one_cate_id: this.classify.stairSecond[this.classify.stairfl].id,
        two_cate_id: this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id,
        name_eng: this.newmerchandise.English,
        name_py: this.newmerchandise.phoneticize,
        name: this.newmerchandise.name,
        price: this.newmerchandise.price == '时价' ? '0' : this.newmerchandise.price,
        prd_type: Number(this.newmerchandise.SKUtype),
        biz_type: Number(this.newmerchandise.businesstype),
        erp_prd_id: this.newmerchandise.inventory.id,
        regions: s,
        mklibs: w,
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.QuantityProduction = false
          // console.log(res);
          this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
        } else {
          this.$message({message: res.msg, type: 'error'})
        }
      })
    },
    // 打开新增套餐
    newsetmeal(){
      if (this.pdddymy) {
        this.singlecommodities = true
        this.newsetmeals = true
        this.setmeallist = []
        this.demand()
        this.setmeals = {
          id: '',
          name: '',//物料名称
          phoneticize: '',//拼音
          English: '',//英文名
          price: '',//单价
          one_cate_id: 0,//一级id
          two_cate_id: 0,//二级id
          is_force: 2,
        }//套餐
        this.substitute = []
        this.nature_isIndeterminate = false
        this.nature_checkAll = false
        this.nature_checkedCities = []
        for (const key in this.regions) {
          this.nature_checkedCities.push(this.regions[key].id)
        }
        console.log(this.regions);
        if (this.nature_checkedCities.length > 0) {
          this.nature_checkAll = true
        }


        this.$nextTick(() => {  //次要代码
          this.$refs.xidhf.focus();
        })
      } else {
        this.$message({showClose: true, message: "没有二级分类，请先创建二级分类", type: 'warning',})
      }
    },
    // 套餐新增单品
    additional(judge, index){
      this.contcture = '2'
      this.ImportDatas = []
      this.estimategdthz = judge
      if (!judge) {
        this.Whichoneadd = index
      }
      this.get_set_items.name = ''
      this.get_set_items.page_num = 1
      this.get_set_items.is_init = 1
      this.setmeals.one_cate_id = 0
      this.setmeals.two_cate_id = 0
      this.commoditycode = []
      this.newexhibits = true
      this.checkedCitispes = []
      this.$api.BMS.Prd.requestprdget_set_items({
        name: this.get_set_items.name,
        page_num: this.get_set_items.page_num,
        page_size: this.get_set_items.page_size,
        is_init: this.get_set_items.is_init,
        one_cate_id: this.setmeals.one_cate_id,
        two_cate_id: this.setmeals.two_cate_id
      }).then(res => {
        // console.log(res);
        if (res.code == 1) {
          this.dcommoditytems = res.data.cates || []
          if (res.data.items) {
            // console.log(res.data.items);
            // console.log(this.setmeallist);
            console.log(judge);
            if (judge) {
              for (const key in res.data.items) {
                for (const i in this.setmeallist) {
                  if (res.data.items[key].id == this.setmeallist[i].id) {
                    res.data.items[key].control = true
                    console.log(res.data.items[key]);
                  }
                }
              }
            } else {
              for (const key in res.data.items) {
                for (const i in this.substitute[index].items) {
                  if (res.data.items[key].id == this.substitute[index].items[i].id) {
                    res.data.items[key].control = true
                    console.log(res.data.items[key]);
                  }
                }
              }
            }

          }
          // this.ImportDatas = res.data.items || []
          if (this.$refs.infiniteLoading) {
            this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
          }
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 查询
    gett_wwite(){
      this.contcture = '3'
      this.ImportDatas = []
      setTimeout(() => {
        this.get_set_items.is_init = 2
        this.get_set_items.page_num = 1
        this.$api.BMS.Prd.requestprdget_set_items({
          name: this.get_set_items.name,
          page_num: this.get_set_items.page_num,
          page_size: this.get_set_items.page_size,
          is_init: this.get_set_items.is_init,
          one_cate_id: this.setmeals.one_cate_id,
          two_cate_id: this.setmeals.two_cate_id
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            if (res.data.items == null) {
              this.contcture = '1'
            }
            this.ImportDatas = res.data.items || [];
            if (this.$refs.infiniteLoading) {
              this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
            }
            if (res.data.items) {
              if (this.estimategdthz) {
                for (const key in res.data.items) {
                  for (const i in this.setmeallist) {
                    if (res.data.items[key].id == this.setmeallist[i].id) {
                      res.data.items[key].control = true
                    }
                  }
                }
              } else {
                for (const key in res.data.items) {
                  for (const i in this.substitute[this.Whichoneadd].items) {
                    if (res.data.items[key].id == this.substitute[this.Whichoneadd].items[i].id) {
                      res.data.items[key].control = true
                    }
                  }
                }
              }
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      }, 1000)
    },
    // 无线加载
    infiniteHandler($state) {
      // 这里模仿加载延迟1秒钟
      setTimeout(() => {
        console.log('延迟');
        this.get_set_items.page_num++
        this.$api.BMS.Prd.requestprdget_set_items({
          name: this.get_set_items.name,
          page_num: this.get_set_items.page_num,
          page_size: this.get_set_items.page_size,
          is_init: 2,
          one_cate_id: this.setmeals.one_cate_id,
          two_cate_id: this.setmeals.two_cate_id
        }).then(res => {
          // console.log(res);
          if (res.code == 1) {
            if (res.data.items) {
              if (this.estimategdthz) {
                for (const key in res.data.items) {
                  for (const i in this.setmeallist) {
                    if (res.data.items[key].id == this.setmeallist[i].id) {
                      res.data.items[key].control = true
                    }
                  }
                  this.ImportDatas.push(res.data.items[key])
                }
              } else {
                for (const key in res.data.items) {
                  for (const i in this.substitute[this.Whichoneadd].items) {
                    if (res.data.items[key].id == this.substitute[this.Whichoneadd].items[i].id) {
                      res.data.items[key].control = true
                    }
                  }
                  this.ImportDatas.push(res.data.items[key])
                }
              }
              // for (const iterator of res.data.items) {
              //     this.ImportDatas.push(iterator)
              // }
              $state.loaded();
            } else {
              $state.complete();
            }
          } else {
            this.get_set_items.page_num = this.get_set_items.page_num - 1
            this.$message({message: res.msg, type: 'error'})
          }
        })
      }, 1000);
    },
    // 套餐新增固定单品
    setmealewproduct(){
      if (this.checkedCitispes.length > 0) {
        for (const iterator of this.checkedCitispes) {
          for (const i in this.ImportDatas) {
            if (this.ImportDatas[i].id == iterator) {
              this.setmeallist.push(this.ImportDatas[i])
            }
          }
        }
        this.newexhibits = false
        console.log(this.setmeallist);
      } else {
        this.$message.warning('请选中一个进行添加')
      }
    },
    // 套餐单品删除
    dpdelete(i){
      this.setmeallist.splice(i, 1)
    },
    // 新增替换组
    addtitutiongroups(){
      this.substitute.push({
        sel_cnt: '',
        items: [],
        deletejudge: false
      })
      this.$nextTick(() => {  //次要代码
        var container = this.$refs.rollbott.$el
        container.scrollTop = container.scrollHeight;
      })
    },
    // 给套餐通替换组添加单品
    addchangeof(){
      if (this.checkedCitispes.length > 0) {
        for (const iterator of this.checkedCitispes) {
          for (const i in this.ImportDatas) {
            if (this.ImportDatas[i].id == iterator) {
              this.substitute[this.Whichoneadd].items.push(this.ImportDatas[i])
            }
          }
        }
        this.newexhibits = false
      } else {
        this.$message.warning('请选中一个进行添加')
      }
    },
    // 删除替换组单品
    dpdeletereplace(j, i){
      this.substitute[j].items.splice(i, 1)
    },
    // 删除替换组
    deletereplace(i){
      this.substitute.splice(i, 1)
    },
    // 新增套餐
    addsetmeal(){
      if (this.setmeallist.length == 0) {
        this.$message({message: '请添加单品信息', type: 'error'})
      } else {
        console.log(this.setmeallist);
        var fix_items = []
        var rpl_items = []
        for (const key in this.setmeallist) {
          fix_items.push({
            pid: this.setmeallist[key].id,
            pc: Number(this.setmeallist[key].pc ? this.setmeallist[key].pc : 1)
          })
        }
        for (const key in this.substitute) {
          if (this.substitute[key].items.length > 0) {
            var items = []
            for (const ky in this.substitute[key].items) {
              items.push({
                pid: this.substitute[key].items[ky].id,
                pc: Number(this.substitute[key].items[ky].pc ? this.substitute[key].items[ky].pc : 1)
              })
            }
            rpl_items.push({
              sel_cnt: Number(this.substitute[key].sel_cnt),
              items: items
            })
          }
        }
        var region_ids = []
        for (const key in this.regions) {
          for (const ke in this.nature_checkedCities) {
            if (this.regions[key].id == this.nature_checkedCities[ke]) {
              region_ids.push(this.regions[key].id)
            }
          }
        }
        this.$api.BMS.Prd.requestprdnew_set({
          name: this.setmeals.name,
          one_cate_id: this.classify.stairSecond[this.classify.stairfl].id,
          two_cate_id: this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id,
          name_eng: this.setmeals.English,
          name_py: this.setmeals.phoneticize,
          price: this.setmeals.price,
          is_force: Number(this.setmeals.is_force),
          fix_items: fix_items,
          rpl_items: rpl_items,
          region_ids: region_ids
        }).then(res => {
          console.log(res);
          if (res.code == 1 || res.code == 6) {
            this.newsetmeals = false
            if (res.msg === '') {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: 'success'
              })
            } else {
              this.$message({
                showClose: true,
                message: res.msg,
                type: 'warning'
              })
            }
            this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          } else if (res.code == 2) {
            this.deletealtative = true
          } else if (res.code == 3) {
            this.Seterrortxsf = true
            this.Seterrorthree = {
              data: res.data,
              msg: res.msg
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      }

    },
    // 强制添加
    compellent(){
      this.deletealtative = false
      this.setmeals.is_force = 1
      this.addsetmeal()
    },
    // 编辑套餐
    Editpackage(){
      this.$api.BMS.Prd.requestprdget_set({id: this.checkedCities[0]}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.setmeals = {
            id: res.data.id,
            name: res.data.name,
            one_cate_id: res.data.one_cate_id,
            two_cate_id: res.data.two_cate_id,
            phoneticize: res.data.name_py || '',
            English: res.data.name_eng || '',
            price: res.data.price,
            is_force: 2,//是否强制添加, 1 强制添加 2  普通模式添加
          }
          this.setmeallist = res.data.fix_items || []
          this.nature_checkedCities = res.data.sel_region_ids || []
          if (res.data.sel_region_ids.length == 0) {
            this.nature_isIndeterminate = false
            this.nature_checkAll = false
          } else if (this.regions.length == res.data.sel_region_ids.length) {
            this.nature_checkAll = true
          } else {
            this.nature_isIndeterminate = true
          }
          this.substitute = []
          for (const key of res.data.rpl_items || []) {
            this.substitute.push({
              sel_cnt: key.sel_cnt,
              items: key.items,
              deletejudge: false
            })
          }

          this.singlecommodities = false
          this.newsetmeals = true
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 保存编辑套餐
    saveitpackage(){
      if (this.setmeallist.length == 0) {
        this.$message({message: '请添加单品信息', type: 'error'})
      } else {
        console.log(this.setmeallist);
        var fix_items = []
        var rpl_items = []
        for (const key in this.setmeallist) {
          fix_items.push({
            pid: this.setmeallist[key].id,
            pc: Number(this.setmeallist[key].pc ? this.setmeallist[key].pc : 1)
          })
        }
        for (const key in this.substitute) {
          if (this.substitute[key].items.length > 0) {
            var items = []
            for (const ky in this.substitute[key].items) {
              items.push({
                pid: this.substitute[key].items[ky].id,
                pc: Number(this.substitute[key].items[ky].pc ? this.substitute[key].items[ky].pc : 1)
              })
            }
            rpl_items.push({
              sel_cnt: Number(this.substitute[key].sel_cnt),
              items: items
            })
          }
        }
        var region_ids = []
        for (const key in this.regions) {
          for (const ke in this.nature_checkedCities) {
            if (this.regions[key].id == this.nature_checkedCities[ke]) {
              region_ids.push(this.regions[key].id)
            }
          }
        }
        this.$api.BMS.Prd.requestprdsave_set({
          id: this.setmeals.id,
          name: this.setmeals.name,
          one_cate_id: Number(this.classify.stairSecond[this.classify.stairfl].id),
          two_cate_id: Number(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id),
          name_eng: this.setmeals.English,
          name_py: this.setmeals.phoneticize,
          price: this.setmeals.price,
          is_force: Number(this.setmeals.is_force),
          fix_items: fix_items,
          rpl_items: rpl_items,
          region_ids: region_ids
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.newsetmeals = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
            this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          } else if (res.code == 2) {
            this.deletealtative = true
          } else if (res.code == 3) {
            this.Seterrortxsf = true
            this.Seterrorthree = {
              data: res.data,
              msg: res.msg
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      }
    },
    // 无效
    noneffective(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.Prd.requestprddisable({
          ids: this.checkedCities,
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
            this.checkedCities = []
            this.isIndeterminate = false
            this.checkAll = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 2) {
            this.invalidive = true
            this.scwxvalidive = true
            this.invalidree = {
              data: res.data,
              msg: res.msg
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请选择一个进行更改状态',
          type: 'warning',
        })
      }
    },
    // 有效
    effective(){
      if (this.checkedCities.length > 0) {
        this.$api.BMS.Prd.requestprdenable({
          ids: this.checkedCities,
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
            this.checkedCities = []
            this.isIndeterminate = false
            this.checkAll = false
            this.$message({
              showClose: true,
              message: "操作成功",
              type: 'success'
            })
          } else if (res.code == 3) {
            this.pandsansi = true
            this.roductibrive = true
            this.Productibrary = {
              data: res.data,
              msg: res.msg
            }
          } else if (res.code == 4) {
            this.pandsansi = false
            this.roductibrive = true
            this.Productibrary = {
              data: res.data,
              msg: res.msg
            }
          } else {
            this.$message.warning(res.msg)
          }
        })
      } else {
        this.$message({
          message: '请选择一个进行更改状态',
          type: 'warning',
        })
      }
    },
    // 批量删除
    DelPayChannel(){
      this.$api.BMS.Prd.requestprddel({ids: this.checkedCities}).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)
          this.isIndeterminate = false
          this.checkAll = false
          this.checkedCities = []
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
        } else if (res.code == 2) {
          this.invalidive = true
          this.scwxvalidive = false
          this.invalidree = {
            data: res.data,
            msg: res.msg
          }
        } else {
          this.$message({message: res.msg, type: 'warning'})
        }
      })
    },
    //获取焦点
    edit(){
      this.$nextTick(() => {  //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs.selectsse);
      })
    },
  },
  computed: {
    setmea(){
      return JSON.parse(JSON.stringify(this.setmeals))
    },
    newmerchand(){
      return JSON.parse(JSON.stringify(this.newmerchandise))
    },
    watc(){
      return JSON.parse(JSON.stringify(this.classify))
    },
    substute(){
      return JSON.parse(JSON.stringify(this.substitute))
    },
    checkedCitisp(){
      return JSON.parse(JSON.stringify(this.checkedCitispes))
    },

  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val)
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt (val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    dept_code: {
      deep: true,
      handler: function (after, before) {
        console.log(after[after.length - 1]);
        this.erp_prds.erp_cate_code = after[after.length - 1]

        // this.prderp_prds()
        this.checkedCitispes = []
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false
        }
      }
    },
    commoditycode: {
      deep: true,
      handler: function (after, before) {
        // this.erp_prds.erp_cate_code = after[after.length-1]
        console.log(after);
        this.setmeals.one_cate_id = after[0] || 0
        this.setmeals.two_cate_id = after[1] || 0
        // this.gett_wwite()
        // this.checkedCitispes = []
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false
        }
      }
    },
    // 监听每换一下分类商品也会换
    watc: {
      deep: true,
      handler: function (after, before) {
        console.log(after);
        if (after.stairfl != before.stairfl) {
          this.classify.Secondfl = 0
          this.checkAll = false
          this.checkedCities = []
          this.isIndeterminate = false
        }
        // console.log(after.stairfl != before.stairfl);
        if (after.Secondfl != before.Secondfl) {
          this.checkAll = false
          this.checkedCities = []
          this.isIndeterminate = false
        }
        console.log(after.stairSecond[after.stairfl]);

        if (after.stairSecond[after.stairfl]) {

          if (after.stairSecond[after.stairfl].ss) {
            this.pdddymy = true
            this.refresh(this.classify.stairSecond[this.classify.stairfl].ss[this.classify.Secondfl].id)

          } else {
            console.log(1);
            this.pdddymy = false
            // this.$message({showClose:true,message:"没有二级分类，请先创建二级分类", type: 'warning',})
            this.merchandise = []
          }
        }

      }
    },
    // 根据商品名称改变拼音 限制价格
    newmerchand: {
      deep: true,
      handler: function (after, before) {
        // console.log(/^[a-zA-z]$/.test(after.English));
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util.requestutilpy({str: after.name}).then(res => {
            this.newmerchandise.phoneticize = res.data || ''
          })
        }
        if (after.SKUtype == 4 || after.SKUtype == 5 || after.SKUtype == 6) {
          this.newmerchandise.Inventorygoods = false
        } else {
          this.newmerchandise.Inventorygoods = true
        }
        if (after.SKUtype == 3 || after.SKUtype == 4 || after.SKUtype == 5 || after.SKUtype == 6) {
          this.newmerchandise.businesstype = '2'
          this.newmerchandise.forbidden = true
        }
        if (before.SKUtype != after.SKUtype) {
          if (after.SKUtype == 1 || after.SKUtype == 6) {
            if (after.price == before.price) {
              this.newmerchandise.price = ''
              this.newmerchandise.marketprices = false
            }
          }
        }
        if (after.SKUtype == 3 || after.SKUtype == 4 || after.SKUtype == 5) {
          this.newmerchandise.price = '时价'
          this.newmerchandise.marketprices = true
        }
        if (after.SKUtype == 1) {
          this.newmerchandise.forbidden = false
        }
      }
    },
    // 根据商品名称改变拼音 限制价格
    setmea: {
      deep: true,
      handler: function (after, before) {
        // console.log(/^[a-zA-z]$/.test(after.English));
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util.requestutilpy({str: after.name}).then(res => {
            this.setmeals.phoneticize = res.data || ''
          })
        }
      }
    },
    // 判断替换组可选数量  进行限制
    substute: {
      deep: true,
      handler: function (after, before) {
        var i = ''
        if (after.length == before.length) {
          for (const key in after) {
            if (after[key].sel_cnt != before[key].sel_cnt) {
              var reg = /^[0-9]*$/
              if (!reg.test(after[key].sel_cnt)) {
                this.substitute[key].sel_cnt = before[key].sel_cnt
                this.$message.warning('请输入数字')
              } else if (after[key].sel_cnt.length > 4) {
                this.substitute[key].sel_cnt = before[key].sel_cnt
                this.$message.warning('最大支持四位数字')
              } else if (parseInt(after[key].sel_cnt) === 0) {
                this.substitute[key].sel_cnt = ''
                this.$message.warning('输入必须大于零')
              }
            }
            if (after[key].deletejudge != before[key].deletejudge) {
              if (after[key].deletejudge == true) {
                i = Number(key)
              }
            }
          }
          if (typeof(i) == 'number') {
            for (const key in after) {
              if (i == key) {
                this.substitute[key].deletejudge = true
              } else {
                this.substitute[key].deletejudge = false
              }
            }
          }
        }
      }
    },
    checkedCitisp: {
      deep: true,
      handler: function (after, before) {
        if (after.length > 1) {

          this.checkedCitispes = after.slice(-1)
          console.log(this.checkedCitispes);
        }
      }
    },


  }
}
</script>
<style>
    /* 靠右 */
    .Prd .el-dialog {
        margin: 0px 0px 0px auto !important;
        background-color: #f9f9f9;
        height: 100%;
        position: relative;
    }

    .Prd .el-dialog__footer {
        position: absolute;
        width: 100%;
        bottom: 0;
        right: 0;
        display: flex;
        justify-content: center;
    }

    .Prd .el-dialog__body {
        padding: 0px 0px 30px 20px;
        overflow-y: scroll !important;
        /* width: 100%; */
        width: calc(100% - 40px);
        height: calc(100% - 160px);
        max-height: calc(100% - 160px);
        margin: 0;
    }

    .Prd .el-dialog {
        box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1)
    }

    .Prd {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    /* 金额 */
    .money {
        text-align: right !important;
        width: 80%;
        padding: 0 10px;
    }

    .alignment .el-input__inner {
        text-align: right !important;
    }

    /* ERP商品 */
    .Prd .in_sum-rkrq {
        color: #40404e;
        padding: 20px 0;
        display: flex;

    }

    .Prd .in_sum-rkrq .rkrq {
        margin-right: 15px;
        /* width: 280px; */
        display: flex;
        align-items: center;
    }

    .Prd .in_sum-rkrq .el-cascader__dropdown {
        background-color: #f5f5f5;
    }

    .Prd .in_sum-rkrq .rkrq > span {
        width: 50px;
        display: inline-block;
    }

    .Prd .in_sum-rkrq .rkrq .el-select {
        width: 230px;
    }

    .Prd .in_sum-rkrq .rkrq .el-input {
        width: 220px;
    }

    .Prd .in_sum-rkrq .rkrq:nth-of-type(3) {
        width: 240px;
    }

    /* 级联选择器 */
    .liebdwd .el-radio__inner {
        top: -18px;
        left: -19px;
        border-radius: 0;
        border: 0;
        width: 170px;
        height: 34px;
        background-color: transparent;
        cursor: pointer;
        box-sizing: border-box;
        position: absolute;
    }

    .liebdwd .el-radio__input.is-checked .el-radio__inner {
        background: transparent;
    }

    /* 禁用状态颜色 */
    .Prd .dialogPrinter .el-input.is-disabled .el-input__inner {
        background-color: rgba(255, 255, 255, 0.075) !important;
        color: #b2b7c0
    }

    .Prd .dialogPrinter .el-form {
        padding-top: 0px !important;
    }

    /* 必填 */
    .Prd .mandatory {
        color: #40404e;
        width: 140px;
        text-align: right;
        /*padding-top: 10px;*/
    }

    .Prd .controlling {
        width: 230px !important;
        color: #40404e;
        line-height: 40px;
        height: 40px;
    }

    .Prd .reqfieldsd {
        font-size: 16px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 表格全选字体颜色 */
    .Prd .between .zhuixiaoi .el-checkbox__label {
        color: #40404e;
    }

    .Prd .between .zhuixiaoi .mmodity .el-checkbox__label {
        font-size: 12px;
    }

    /* 一级分类下没二级分类的时候 */
    .Prd .between {
        display: flex;
        flex-direction: column;
        align-items: center;
        margin-top: 170px;
        padding-right: 400px;
    }

    .Prd .between img {
        width: 100px;
        height: 100px;
    }

    .Prd .between .period {
        margin-top: 30px;
        color: #a3a3a3;
        font-size: 18px;
    }

    /* */
    /* 选中状态颜色背景边框 */
    .Prd .el-radio-button__orig-radio:checked + .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #6A9EFF !important;
        color: #6A9EFF !important;
        box-shadow: none;
    }

    /* 表格无数据时展示 */
    .Prd .tiaodd {
        position: sticky;
        left: 0;
        top: 44px;
        width: 100% !important;
        display: inline-block;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .nodata {
        width: 100% !important;
        height: 250px !important;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        padding: 0;
    }

    .Prd .nodata img {
        width: 60px;
        height: 60px;
    }

    .Prd .nodata .hint {
        line-height: 36px;
        font-size: 13px !important;
    }

    /* 限制一级分类二级分类宽带 */
    .Prd .stairastrict {
        max-width: 1000px;
        flex-shrink: 0
    }

    /* 给一级分类二级分类加外边距和圆角 */
    .Prd .el-radio-button {
        margin-right: 6px;
        margin-bottom: 6px;
        /* overflow: hidden; */
        /* border: 1px solid #f5f5f5; */
    }

    .Prd .el-radio-button__inner {
        border-radius: 4px !important;
        padding: 6px 20px;
        font-size: 14px;
        height: 30px;
    }

    .Prd .el-radio-button__inner-div {

        padding: 0 20px;
    }

    /* 去除瑕疵 */
    .Prd .el-radio-button__orig-radio:checked + .el-radio-button__inner + {
        box-shadow: none
    }

    /*去除双击文字、input等，出现的蓝色底色*/
    .container {
        -moz-user-select: none; /*火狐*/
        -webkit-user-select: none; /*webkit浏览器*/
        -ms-user-select: none; /*IE10*/
        /*-khtml-user-select:none;!*早期浏览器*!*/
        user-select: none;
        height: 30px;
    }

    .Prd-headline {
        font-size: 30px;
        font-weight: bold;
        color: #40404e;
    }

    .Prd-controller {
        /*margin-top: 30px;*/
        height: 54px;
        /*width: 1600px;*/
        background-color: #eee;
        display: flex;
        align-items: center;
    }

    .Prd table {
        border-collapse: collapse;
        /* border: solid 1px #f5f5f5; */
        color: #40404e;
    }

    .Prd table thead th {
        height: 40px;
        /* min-height: 40px; */
        line-height: 40px;
        text-align: center;
        border-top: solid 1px #f5f5f5;
        border-right: solid 1px #f5f5f5;
        border-bottom: solid 1px #f5f5f5;
        background-color: #f5f5f5;
        font-weight: 600;
        font-size: 14px;
    }

    .Prd table tbody td {
        height: 40px;
        min-height: 40px;
        line-height: 20px;

        text-align: center;
        white-space: normal;
        word-break: break-all;
        /* border: solid 1px #f5f5f5; */
        border-bottom: solid 1px #f5f5f5;
        border-right: solid 1px #f5f5f5;
        font-size: 14px;
        font-weight: 400;

    }

    .Prd .el-checkbox__label {
        color: #40404e;
    }

    .Prd th .el-checkbox__label {
        color: #40404e;
        font-size: 14px;
        font-weight: 600;
        color: #1a1a21;
    }

    .Prd .List-move {
        transition: transform 0.2s;
    }

    .Prd .zhuixiaoi {
        min-width: 867px;
        overflow: hidden;
        display: inline-block;
        margin-top: 6px;
    }

    .Prd .zhuixiaoi .limiting {
        width: 100%;
        overflow: auto !important;
        max-height: 540px;
        display: block;
    }

    .Prd .tolead .el-dialog {
        width: 30vw !important;
        min-width: 410px !important;
        max-width: 460px !important;
    }

    .Prd .feedback .el-dialog {
        width: 1300px !important;
    }

    .Prd .zhuixiaoi thead, .Prd .zhuixiaoi thead tr, .Prd .zhuixiaoi tbody tr {
        width: 100% !important;
    }

    .Prd .zhuixiaoi .drag-list {
        display: inline-block;
        width: 100% !important;
    }

    .Prd .check {
        color: #40404e;
    }

    .Prd .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .Prd .el-dialog {
        background-color: #f9f9f9;
    }

    .Prd .el-input__inner {
        background-color: transparent;
        color: #40404e;
    }

    .Prd .el-dialog__header, .Prd .el-dialog__footer {
        background-color: #eee;
    }

    .Prd .el-dialog__title, .Prd .el-dialog__headerbtn .el-dialog__close, .Prd .el-form-item__label {
        color: #1a1a21;
        display: flex;
        align-items: center;
    }

    .Prd .el-form-item {
        display: flex;
        margin: 0;
    }

    /* 改变多选框背景颜色和上下间距 */
    .Prd .el-checkbox-group {
        display: flex;
        align-items: flex-end;
        justify-content: center;
    }

    .Prd .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .Prd .el-dialog {
        width: 30vw;
    }

    .Prd .has-gutter {
        border: 1px solid #f5f5f5;
    }

    .Prd .el-input-number__decrease, .Prd .el-input-number__increase {
        background-color: rgba(0, 0, 0, 0);
    }

    .Prd .el-radio__label {
        color: #40404e;
    }

    .Prd .el-input__inner {
        background-color: transparent !important;
    }
</style>
<style>
    /* 一级分类和二级分类文字颜色更改 */
    .Prd .stairfl {
        display: flex;
        align-items: center;
        margin: 0 0 14px 0;
        font-size: 13px;
        line-height: 14px;
    }

    .Prd .stairfl .classification {
        width: 70px;
        color: #40404e;
        margin-right: 20px;
        font-size: 13px;
        line-height: 14px;
        padding-top: 10px;
        flex-shrink: 0
    }

    .Prd .stairfl .fl {
        color: #ce4153;
        margin: 0 11px;
        height: 42px;
        line-height: 42px;
    }

    /* 更改单选框颜色 */
    .Prd .el-radio-button__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
        border: 1px solid #f5f5f5;
        font-size: 14px;
    }

    .Prd .el-radio-button:first-child .el-radio-button__inner {
        border-left: 1px solid #f5f5f5;
    }

    /* 更改按钮字体大小 */
    .Prd .el-button {
        font-size: 14px;
    }

    /* 新建商品 */
    .Prd .dialogPrinter .el-dialog {
        width: 790px;
        /*margin-top: 50px !important;*/
    }

    .Prd .dialogPrinter .el-dialog__body {
        padding: 10px;
    }

    .Prd .dialogPrinter .Materialunit {
        border: 1px solid #40404e;
        padding: 10px;
    }

    .Prd .dialogPrinter .biaot {
        font-size: 24px;
        color: #40404e;
        text-align: center;
        margin-bottom: 10px;
    }

    .Prd .dialogPrinter .compa-tib {
        color: #40404e;
    }

    .Prd .dialogPrinter .rial-unit {
        display: flex;
    }

    .Prd .dialogPrinter .rial-unit div {
        width: 530px;
        margin-left: 20px;
        color: #40404e;
    }

    .Prd .dialogPrinter .el-button--mini, .el-button--small {
        font-size: 14px !important;
    }

    .Prd .compatibil {
        margin-bottom: 10px;
    }

    .Prd .compatibility {
        display: flex;
        margin-bottom: 5px;
    }

    .Prd .dialogPrinter .Mater-unit {
        margin-top: 10px;
        font-size: 14px;
        overflow: hidden;
        display: inline-block;
        border-left: 1px solid #f5f5f5;
    }

    .Prd .dialogPrinter .limiting {
        width: 100%;
        overflow: auto !important;
        max-height: 210px !important;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    /* 单品商品区域 */
    .Prd .dialogPrinter .annkz {
        display: flex;
        justify-content: center;
    }

    .Prd .dialogPrinter .extend-unit {
        margin-left: 70px;
        font-size: 14px;
        overflow: inherit;
        display: inline-block;
        border-left: 1px solid #f5f5f5;
    }

    .Prd .dialogPrinter .extend-unit .drag-list td:nth-of-type(1), .Prd .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .dialogPrinter .extend-unit .drag-list td:nth-of-type(2), .Prd .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
        width: 230px;
    }

    .Prd .dialogPrinter .extend-unit .drag-list td:nth-of-type(3), .Prd .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Prd .dialogPrinter .extend-unit .drag-list td:nth-of-type(4), .Prd .dialogPrinter .extend-unit .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    /* 绑定epr商品 */
    .Prd .user-defined .el-dialog {
        width: 650px !important;
    }

    .Prd .user-defined .explain {
        margin-top: 20px;
        color: #ce4153;
        font-size: 12px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .user-defined .el-form {
        padding-top: 20px !important;
    }

    .Prd .user-defined .attribute {
        width: 350px;
        display: flex;
        flex-direction: column;
    }

    .Prd .user-defined .el-input {
        width: 230px;
    }

    .Prd .user-defined .el-form-item__content {
        display: flex;
        margin-bottom: 10px;
    }

    .Prd .user-defined .compatibil .compatibility {
        align-items: flex-start;
    }

    .Prd .user-defined .compatibil .compatibility .el-button {
        width: 40px;
        height: 40px;
        margin-left: 10px;
    }

    .Prd .user-defined .zhuixiaoi {
        min-width: 602px !important;
        width: 602px;
        overflow: hidden;
        display: inline-block;
    }

    .Prd .user-defined .drag-list td:nth-of-type(1), .Prd .user-defined .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .user-defined .drag-list td:nth-of-type(2), .Prd .user-defined .mmodity th:nth-of-type(2) {
        width: 240px;
    }

    .Prd .user-defined .drag-list td:nth-of-type(3), .Prd .user-defined .mmodity th:nth-of-type(3) {
        width: 210px;
    }

    .Prd .user-defined .drag-list td:nth-of-type(4), .Prd .user-defined .mmodity th:nth-of-type(4) {
        width: 70px;
    }

    /* 新建套餐 */
    .Prd .dialogsetmeal .el-dialog {
        width: 1280px;
        /*margin-top: 50px !important;*/
        /*margin-bottom: 50px !important;*/
    }

    .Prd .dialogsetmeal .el-form {
        padding-top: 5px;
    }

    .Prd .dialogsetmeal .tbdgf img {
        width: 15px;
        height: 15px;
    }

    .Prd .dialogsetmeal .item {
        margin: 4px 4px 4px -5px;
    }

    .Prd .dialogsetmeal .el-dialog__body {
        padding: 10px;
    }

    .Prd .dialogsetmeal .Materialunit {
        border: 1px solid #40404e;
        padding: 10px;
    }

    .Prd .dialogsetmeal .biaot {
        font-size: 24px;
        color: #40404e;
        text-align: center;
        margin-bottom: 10px;
    }

    .Prd .dialogsetmeal .compa-tib {
        color: #40404e;
    }

    .Prd .dialogsetmeal .rial-unit {
        display: flex;
    }

    .Prd .dialogsetmeal .rial-unit div {
        width: 530px;
        margin-left: 20px;
        color: #40404e;
    }

    .Prd .dialogsetmeal .el-button--mini, .el-button--small {
        font-size: 14px !important;
    }

    .Prd .compatibil {
        margin-bottom: 10px;
    }

    .Prd .compatibility {
        display: flex;
        margin-bottom: 5px;
    }

    .Prd .dialogsetmeal .Mater-unit {
        margin-top: 10px;
        font-size: 14px;
        overflow: hidden;
        display: inline-block;
        border-left: 1px solid #f5f5f5;
    }

    .Prd .dialogsetmeal .limiting {
        width: 100%;
        display: block;
    }

    /* 固定单品 */
    .Prd .dialogsetmeal .annkz {
        display: flex;
        justify-content: center;
    }

    .Prd .dialogsetmeal .extend-unit {
        /* width: 1120px; */

        margin-left: 70px;
        font-size: 14px;
        overflow: inherit;
        display: inline-block;
    }

    /* 表格无数据时展示 */
    .Prd .dialogsetmeal .extend-unit .drag-list .nodata {
        height: 100px !important;
        border-left: none;
        padding: 0;
        width: 1128px !important;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list {
        width: 100%;
        display: inline-block;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list .Theewitem {
        cursor: pointer;
        display: inline-block;
        height: 50px;
        display: flex;
        justify-content: center;
        align-items: center;
        padding: 0;
        width: 1128px !important;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list .Theewitem div:nth-of-type(1) {
        color: #438dfd;
        font-size: 15px;
        font-weight: bold;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list .Theewitem div:nth-of-type(2) {
        color: #438dfd;
        font-size: 15px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(1), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(1) {
        width: 49px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(2), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(3), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(3) {
        width: 210px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(4), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(5), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(5) {
        width: 120px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(6), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(6) {
        width: 140px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(7), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(7) {
        width: 90px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(8), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(8) {
        width: 70px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(9), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(9) {
        width: 70px;
    }

    .Prd .dialogsetmeal .extend-unit .drag-list td:nth-of-type(10), .Prd .dialogsetmeal .extend-unit .mmodity th:nth-of-type(10) {
        width: 50px;
    }

    /* 可替换 */
    .Prd .dialogsetmeal .keorganize {
        display: flex;
        flex-direction: column;
        margin-bottom: 30px;
    }

    .Prd .dialogsetmeal .grouphandle {
        padding: 0 30px;
        height: 50px;
        display: flex;
        justify-content: space-between;
        margin-left: 70px;
        border: solid 1px #f5f5f5;
        border-bottom: 0px;
        align-items: center;
        width: 1068px;
    }

    .Prd .dialogsetmeal .choice {
        height: 60px;
        font-size: 20px;
        color: #40404e;
        display: flex;
        justify-content: flex-start;
        align-items: center;
    }

    .Prd .dialogsetmeal .deletereplace {
        font-size: 20px;
        color: #438dfd;
        cursor: pointer;
        margin-right: 20px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .dialogsetmeal .reddeletereplace {
        font-size: 20px;
        color: #fd4353;
        cursor: pointer;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 可替换组高亮 类目更改 */
    .Prd .highlight .grouphandle {
        border: solid 2px #ce4153;
        border-bottom: 0px;
    }

    .Prd .highlight .extend-unit .mmodity th:nth-of-type(1) {
        border-left: 2px solid #ce4153 !important;
    }

    .Prd .highlight .extend-unit .drag-list td:nth-of-type(1) {
        border-left: 2px solid #ce4153 !important;
    }

    .Prd .highlight .extend-unit .mmodity th:nth-of-type(10), .Prd .highlight .extend-unit .drag-list td:nth-of-type(10) {
        border-right: 2px solid #ce4153 !important;
    }

    .Prd .highlight .extend-unit .drag-list .nodata {
        border-left: 2px solid #ce4153 !important;
        border-right: 2px solid #ce4153 !important;
    }

    .Prd .highlight .extend-unit .drag-list .Theewitem {
        border-left: 2px solid #ce4153 !important;
        border-bottom: 2px solid #ce4153 !important;
        border-right: 2px solid #ce4153 !important;
    }

    /* 提示 */
    .hintimg {
        width: 15px;
        height: 15px;
        margin: 0px 0px 25px 5px;
    }

    /* 新增替换组 */
    .Prd .dialogsetmeal .setaddmeal {
        margin-left: 70px;
        border: dotted 3px #f5f5f5;
        width: 1128px !important;
        margin-bottom: 50px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .dialogsetmeal .setaddmeal .select {
        height: 60px;
        padding-left: 30px;
        font-size: 20px;
        color: #40404e;
        display: flex;
        justify-content: flex-start;
        align-items: center;
        opacity: 0.25
    }

    .Prd .dialogsetmeal .setaddmeal .select div {
        height: 40px;
        border: solid 2px #f5f5f5;
        padding: 0px 20px;
        line-height: 40px;
    }

    .Prd .dialogsetmeal .setaddmeal .extend-unit {
        margin-left: 0px;
        opacity: 0.25
    }

    .Prd .dialogsetmeal .setaddmeal .taddmeal {
        color: #438dfd;
        font-size: 24px;
        font-weight: 500;
        display: inline-block;
        height: 70px;
        display: flex;
        justify-content: center;
        align-items: center;
        width: 100%;
    }

    .Prd .dialogsetmeal .setaddmeal .taddmeal span {
        font-size: 20px;
        font-weight: bold;
    }

    /* 套餐区域 */
    .Prd .dialogsetmeal .extend-unis .limiting {
        width: 100%;
        overflow: auto !important;
        max-height: 210px !important;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    .Prd .dialogsetmeal .extend-unis {
        margin-left: 70px;
        font-size: 14px;
        overflow: inherit;
        display: inline-block;
        border-left: 1px solid #f5f5f5;
    }

    .Prd .dialogsetmeal .extend-unis .drag-list td:nth-of-type(1), .Prd .dialogsetmeal .extend-unis .mmodity th:nth-of-type(1) {
        width: 80px;
    }

    .Prd .dialogsetmeal .extend-unis .drag-list td:nth-of-type(2), .Prd .dialogsetmeal .extend-unis .mmodity th:nth-of-type(2) {
        width: 700px;
    }

    .Prd .dialogsetmeal .extend-unis .drag-list td:nth-of-type(3), .Prd .dialogsetmeal .extend-unis .mmodity th:nth-of-type(3) {
        width: 340px;
    }

    /* 套餐绑定单品 */
    .Prd .newdefined .loadmore {
        height: 40px;
        line-height: 40px;
        border-left: solid 1px #f5f5f5;
        border-right: solid 1px #f5f5f5;
    }

    .Prd .newdefined .el-dialog {
        width: 1100px !important;
    }

    .Prd .newdefined .zhuixiaoi .limiting {

        overflow-y: auto !important;
        max-height: 340px !important;
        border-bottom: solid 1px #f5f5f5;
        display: block;
    }

    .Prd .newdefined .explain {
        margin-top: 20px;
        color: #ce4153;
        font-size: 12px;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .Prd .newdefined .el-form {
        padding-top: 20px !important;
    }

    .Prd .newdefined .attribute {
        width: 350px;
        display: flex;
        flex-direction: column;
    }

    .Prd .newdefined .el-input {
        width: 230px;
    }

    .Prd .newdefined .el-form-item__content {
        display: flex;
        margin-bottom: 10px;
    }

    .Prd .newdefined .compatibil .compatibility {
        align-items: flex-start;
    }

    .Prd .newdefined .compatibil .compatibility .el-button {
        width: 40px;
        height: 40px;
        margin-left: 10px;
    }

    .Prd .newdefined .zhuixiaoi {
        min-width: 602px !important;
        overflow: hidden;
        display: inline-block;
    }

    .Prd .newdefined .drag-list td:nth-of-type(1), .Prd .newdefined .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(2), .Prd .newdefined .mmodity th:nth-of-type(2) {
        width: 240px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(3), .Prd .newdefined .mmodity th:nth-of-type(3) {
        width: 210px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(4), .Prd .newdefined .mmodity th:nth-of-type(4) {
        width: 100px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(5), .Prd .newdefined .mmodity th:nth-of-type(5) {
        width: 140px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(6), .Prd .newdefined .mmodity th:nth-of-type(6) {
        width: 70px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(7), .Prd .newdefined .mmodity th:nth-of-type(7) {
        width: 90px;
    }

    .Prd .newdefined .drag-list td:nth-of-type(8), .Prd .newdefined .mmodity th:nth-of-type(8) {
        width: 70px;
    }

    /* 套餐单品问题区域 */
    .Prd .Seternewdefed .el-dialog {
        width: 830px !important;
    }

    .Prd .Seternewdefed .ewdefed {
        color: #40404e;
        font-size: 20px;
        margin: 20px 0 10px 10px;
        line-height: 30px;
    }

    .Prd .Seternewdefed .zhuixiaois {
        min-width: 602px !important;
        display: inline-block;
    }

    .Prd .Seternewdefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .Prd .Seternewdefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .Prd .Seternewdefed .divbigesd .xian {
        height: 1px;
        background-color: #f5f5f5;
    }

    .Prd .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(1), .Prd .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(2), .Prd .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(2) {
        width: 270px;
    }

    .Prd .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(3), .Prd .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(3) {
        width: 240px;
    }

    .Prd .Seternewdefed .zhuixiaois .drag-list td:nth-of-type(4), .Prd .Seternewdefed .zhuixiaois .mmodity th:nth-of-type(4) {
        width: 180px;
    }

    /* 有效套餐使用到了被设置为无效的单品 */
    .Prd .invalidefed .el-dialog {
        width: 930px !important;
    }

    .Prd .invalidefed .ewdefed {
        color: #40404e;
        font-size: 20px;
        margin: 20px 0 10px 10px;
        line-height: 30px;
    }

    .Prd .invalidefed .zhuixaoise {
        min-width: 602px !important;
        display: inline-block;
    }

    .Prd .invalidefed .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .Prd .invalidefed .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .Prd .invalidefed .divbigesd .xian {
        height: 1px;
        background-color: #f5f5f5;
    }

    .Prd .invalidefed .zhuixaoise .drag-list td:nth-of-type(1), .Prd .invalidefed .zhuixaoise .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .invalidefed .zhuixaoise .drag-list td:nth-of-type(2), .Prd .invalidefed .zhuixaoise .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Prd .invalidefed .zhuixaoise .drag-list td:nth-of-type(3), .Prd .invalidefed .zhuixaoise .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Prd .invalidefed .zhuixaoise .drag-list td:nth-of-type(4), .Prd .invalidefed .zhuixaoise .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .Prd .invalidefed .zhuixaoise .drag-list td:nth-of-type(5), .Prd .invalidefed .zhuixaoise .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    /* 设置为有效的一级分类下有效单品对应的出品库异常 */
    .Prd .roductibrive .el-dialog {
        width: 1060px !important;
    }

    .Prd .roductibrive .ewdefed {
        color: #40404e;
        font-size: 20px;
        margin: 20px 0 10px 10px;
        line-height: 30px;
    }

    .Prd .roductibrive .divbigesd {
        display: flex;
        flex-direction: column;
    }

    .Prd .roductibrive .divbigesd .data {
        height: 30px;
        line-height: 30px;
    }

    .Prd .roductibrive .divbigesd .xian {
        height: 1px;
        background-color: #f5f5f5;
    }

    .Prd .roductibrive .zhuixaoise {
        min-width: 602px !important;
        display: inline-block;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(1), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(2), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(3), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(4), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(4) {
        width: 160px;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(5), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(5) {
        width: 160px;
    }

    .Prd .roductibrive .zhuixaoise .drag-list td:nth-of-type(6), .Prd .roductibrive .zhuixaoise .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    .Prd .roductibrive .zhuiisese {
        min-width: 602px !important;
        display: inline-block;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(1), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(1) {
        width: 70px;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(2), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(2) {
        width: 200px;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(3), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(3) {
        width: 200px;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(4), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(4) {
        width: 200px;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(5), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(5) {
        width: 200px;
    }

    .Prd .roductibrive .zhuiisese .drag-list td:nth-of-type(6), .Prd .roductibrive .zhuiisese .mmodity th:nth-of-type(6) {
        width: 200px;
    }

    /* 是否强制添加 */
    .Prd .deletealternative .el-dialog {
        width: 700px !important;
    }

    .Prd .deletealternative .del {
        color: #40404e;
        font-size: 20px;
        margin: 30px 10px 0 10px;
        line-height: 30px;
    }

    .Prd .deletealternative .del span:nth-of-type(1) {
        color: #ce4153;
        font-size: 26px;
        font-weight: bold;
    }

    .Prd .deletealternative .del span:nth-of-type(2) {
        color: #ce4153;
    }

    /* 下拉框 */
    .el-select-dropdown__wrap {
        background-color: #f5f5f5;
    }

    .el-select-dropdown__empty {
        background-color: #f5f5f5;
        color: #40404e;
    }

    .el-select-dropdown__item.selected {
        background-color: #e5e5e5;
    }

    .el-select__popper.el-popper[role="tooltip"] {
        border: 1px solid #f5f5f5;
    }

    .el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"] .el-popper__arrow::before {
        border: 1px solid #f5f5f5;
        background-color: #f5f5f5;
    }

    .el-select-dropdown__item.hover, .el-select-dropdown__item:hover {
        background-color: #e5e5e5;
    }

    .el-select-dropdown__item.selected {
        color: #40404e;
    }

    .el-select-dropdown__item {
        color: #40404E
    }

    .el-select-dropdown {
        border: 1px solid #f5f5f5;
    }

    /* 分页 */
    .Prd .Pagination {
        /* width: 1093px; */
        text-align: right;
        margin-top: 20px;
    }

    .Prd .Pagination .el-pagination.is-background .btn-next, .Prd .Pagination .el-pagination.is-background .btn-prev, .Prd .Pagination .el-pagination.is-background .el-pager li {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
        color: #40404e;
    }

    .Prd .Pagination .btn-prev {
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #606266;
    }

    .Prd .Pagination .el-pagination {
        padding: 0;
    }

    .Prd .Pagination .el-pagination .btn-next .el-icon, .Prd .Pagination .el-pagination .btn-prev .el-icon {
        color: #40404e;
    }

    .smPrdgr .Pagination .el-pagination.is-background .el-pager li:not(.disabled).active {
        color: #409EFF;
        background-color: rgba(0, 0, 0, 0);
        border: 1px solid #409EFF;
    }

    /* 级联选择器 */
    .el-cascader__dropdown {
        border: 1px solid #f5f5f5;
    }

    .el-cascader-menu__wrap {
        background-color: #f5f5f5;
    }

    .el-cascader-node:not(.is-disabled):hover {
        background-color: #e5e5e5;
        color: #40404e
    }

    .el-cascader-node.in-active-path, .el-cascader-node.is-active, .el-cascader-node.is-selectable.in-checked-path {
        color: #409EFF !important;
        background-color: #e5e5e5;
    }

    .el-radio__inner::after {
        background-color: #e5e5e5;
    }

    .el-cascader-node__label {
        color: #40404e
    }

    .el-cascader-menu {
        border-right: solid 1px #4d4e5c;
    }
</style>
<style>
    /* 列表 */
    .zsykd {
        width: 100%;
        overflow-x: scroll !important;
    }

    .Prd .zhuixiaoi {
        /* width:1400px; */
        border-collapse: collapse;
        color: #40404e;
    }

    .Prd .zhuixiaoi .mmodity tr th {
        height: 36px;
        line-height: 36px;
        text-align: center;
        background-color: #f5f5f5;
        font-size: 14px;
        font-weight: 600;
        color: #1a1a21;
    }

    .Prd .zhuixiaoi .limiting .drag-list td {
        height: 36px;
        line-height: 36px;
        text-align: center;
        border-right: solid 1px #f5f5f5;
        /* border-top: solid 1px #f5f5f5; */
        font-size: 14px;
        font-weight: 400;
    }

    .Prd .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
        border-left: solid 1px #f5f5f5;
    }

    .Prd .zhuixiaoi .limiting .drag-list {
        display: block;
        display: flex;
    }

    .Prd .zhuixiaoi .mmodity {
        width: 100%;
        display: block;
    }

    .Prd .zhuixiaoi .mmodity tr {
        display: flex;
    }

    .Prd .zhuixiaoi .limiting {
        overflow-y: auto !important;
        max-height: 540px;
        /* border-bottom: solid 1px #f5f5f5; */
        display: block;
    }

    .Prd .drag-list td:nth-of-type(1), .Prd .zhuixiaoi thead th:nth-of-type(1) {
        width: 80px;
    }

    .Prd .drag-list td:nth-of-type(2), .Prd .zhuixiaoi thead th:nth-of-type(2) {
        width: 200px
    }

    .Prd .drag-list td:nth-of-type(3), .Prd .zhuixiaoi thead th:nth-of-type(3) {
        width: 140px;
    }

    .Prd .drag-list td:nth-of-type(4), .Prd .zhuixiaoi thead th:nth-of-type(4) {
        width: 160px;
    }

    .Prd .drag-list td:nth-of-type(5), .Prd .zhuixiaoi thead th:nth-of-type(5) {
        width: 100px;
    }

    .Prd .drag-list td:nth-of-type(6), .Prd .zhuixiaoi thead th:nth-of-type(6) {
        width: 140px;
    }

    .Prd .drag-list td:nth-of-type(7), .Prd .zhuixiaoi thead th:nth-of-type(7) {
        width: 105px;
    }

    .Prd .drag-list td:nth-of-type(8), .Prd .zhuixiaoi thead th:nth-of-type(8) {
        width: 140px;
    }

    .Prd .drag-list td:nth-of-type(9), .Prd .zhuixiaoi thead th:nth-of-type(9) {
        width: 140px;
    }

    .Prd .drag-list td:nth-of-type(10), .Prd .zhuixiaoi thead th:nth-of-type(10) {
        width: 140px;
    }

    .Prd .drag-list td:nth-of-type(11), .Prd .zhuixiaoi thead th:nth-of-type(11) {
        width: 70px;
    }


</style>