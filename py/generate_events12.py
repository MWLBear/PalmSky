import json
import random
import math

# ==========================================
# 1. 基础配置
# ==========================================
TOTAL_EVENTS = 2000

STAGES = [
    "筑基", "开光", "胎息", "辟谷",
    "金丹", "元婴", "出窍", "分神",
    "合体", "大乘", "渡劫", "地仙",
    "天仙", "金仙", "大罗金仙", "九天玄仙"
]

# ==========================================
# 2. 文案库 v3.0 - 全四字短语
# ==========================================

DATA_LOW = [
    {"sub": "灵泉", "acts": ["痛饮灵液", "装瓶保存", "沐浴其中", "静心感悟", "灵泉浸身", "清心寡欲"]},
    {"sub": "石碑", "acts": ["拓印碑文", "参悟古意", "轻轻抚摸", "清理尘埃", "仔细研究", "碑文入心"]},
    {"sub": "野兽", "acts": ["狩猎成功", "驱赶离去", "剥皮取材", "摘取兽丹", "烹饪美食", "皮毛入囊"]},
    {"sub":  "灵草", "acts": ["采摘灵草", "移植返家", "吞服入腹", "守护生长", "精心培育", "药香入鼻"]},
    {"sub": "洞府", "acts": ["仔细探索", "搜刮灵物", "盘膝打坐", "在此休整", "布置阵法", "挖掘宝藏"]},
    {"sub": "行脚商", "acts": ["交易往来", "亲切攀谈", "强行夺取", "出价收购", "讨价还价", "奸商交易"]},
    {"sub": "猎户", "acts": ["施以援手", "向其问路", "留下金两", "救治伤势", "指点迷津", "恩泽四方"]},
    {"sub":  "野果", "acts": ["采食野果", "仔细采摘", "酿造美酒", "收藏保存", "晒干待用", "果香满口"]},
    {"sub":  "寒潭", "acts": ["冰水淬体", "深潜其中", "汲取泉水", "极寒修炼", "冻彻心骨", "寒气入体"]},
    {"sub":  "残剑", "acts": ["拾起残剑", "擦拭锈迹", "感悟剑意", "重铸成刀", "剑气纵横", "寒光四射"]},
    {"sub": "灵果树", "acts": ["摘取灵果", "浇灌灵液", "冥想修行", "移植此地", "守护树木", "果实累累"]},
    {"sub": "石洞", "acts": ["进入探寻", "搜罗宝物", "洞中打坐", "布下阵法", "开凿石室", "深邃幽暗"]},
    {"sub":  "溪流", "acts":  ["溪水洗礼", "戏水嬉耍", "汲取清泉", "以水悟道", "洗净污垢", "水流潺潺"]},
]

PREFIX_LOW = [
    "残破的", "普通的", "路边的", "山间的", "神秘的",
    "微弱的", "凡尘的", "荒废的", "古老的", "偶遇的",
    "幽静的", "荒凉的", "朴素的", "不起眼的", "遗落的", "隐秘的"
]

DATA_MID = [
    {"sub":  "秘境", "acts": ["闯入秘境", "深入探索", "寻找阵眼", "阵中感悟", "破阵而出", "诡异莫名"]},
    {"sub": "长老", "acts": ["恭请指点", "与其论道", "切磋武艺", "专程拜访", "虚心请教", "道法高深"]},
    {"sub": "妖兽", "acts": ["斩杀成功", "将其降伏", "掠取妖丹", "炼化妖血", "妖气冲天", "凶悍无比"]},
    {"sub": "灵脉", "acts": ["汲纳灵气", "截断灵脉", "开辟洞府", "布置聚灵", "脉络纵横", "灵气浓郁"]},
    {"sub": "雷劫", "acts": ["引雷淬体", "硬抗天雷", "体悟雷法", "收集雷液", "雷鸣震天", "电光闪烁"]},
    {"sub": "心魔", "acts": ["坚守本心", "挥剑斩杀", "将其炼化", "无视心魔", "心魔作祟", "暗黑入侵"]},
    {"sub":  "阵法", "acts": ["破阵而入", "参悟奥义", "掌控阵法", "修补残缺", "阵纹闪烁", "玄妙无穷"]},
    {"sub":  "丹炉", "acts": ["开启丹炉", "温养丹火", "取出仙丹", "炼制大药", "丹气缭绕", "丹纹生成"]},
    {"sub": "残魂", "acts": ["搜魂获取", "超度残魂", "吞噬魂质", "询问秘闻", "魂气飘摇", "怨气冲天"]},
    {"sub": "剑意", "acts": ["观摩剑意", "融合剑意", "与其对抗", "收服剑意", "剑气凌厉", "剑意锋锐"]},
    {"sub":  "宗门遗迹", "acts": ["闯入遗迹", "盗取秘宝", "领悟传承", "复兴阵法", "古迹苍凉", "废墟残破"]},
    {"sub": "天地灵物", "acts": ["采摘灵物", "温养灵物", "融合灵力", "献祭祈福", "灵物闪耀", "宝气氤氲"]},
    {"sub": "古老传承", "acts": ["解读玉简", "修习古法", "传承修为", "记录于心", "古籍泛黄", "字迹模糊"]},
    {"sub": "因果线", "acts": ["观察因果", "斩断因果", "利用因果", "陷入漩涡", "因果缠绕", "宿命难逃"]},
]

PREFIX_MID = [
    "上古", "宗门", "千年", "狂暴的", "奇异的", "禁制的",
    "魔化的", "纯净的", "雷霆", "诡秘的", "封印的", "扭曲的",
    "绝世的", "失落的", "危险的", "耀眼的", "压抑的", "诱人的"
]

DATA_HIGH = [
    {"sub": "虚空裂缝", "acts": ["汲取虚能", "法力封印", "踏入虚空", "肉身横渡", "裂缝漆黑", "虚无吞噬"]},
    {"sub": "法则碎片", "acts": ["融合法则", "感悟天地", "铭刻灵魂", "吞噬法力", "碎片闪耀", "大道显现"]},
    {"sub":  "灭世神雷", "acts": ["硬抗天威", "炼入法宝", "以身试法", "吸收真意", "雷鸣如怒", "摧毁万物"]},
    {"sub":  "仙人遗蜕", "acts": ["虔诚祭拜", "搜身取宝", "感悟仙韵", "将其安葬", "遗蜕生辉", "仙气缭绕"]},
    {"sub": "时光长河", "acts": ["逆流而上", "观摩岁月", "捞取未来", "斩断过往", "时光如梦", "沧海桑田"]},
    {"sub": "世界本源", "acts": ["炼化本源", "融合本源", "以身守护", "窃取精髓", "本源闪烁", "造化之力"]},
    {"sub": "太古古神", "acts": ["与其论道", "挑战古神", "聆听教诲", "观察其举", "古神沉睡", "威压无穷"]},
    {"sub":  "仙宫", "acts": ["入主仙宫", "镇压禁制", "开启大门", "重建仙宫", "宫殿雄伟", "金碧辉煌"]},
    {"sub": "域外魔域", "acts": ["杀入魔域", "设置屏障", "炼化魔气", "彻底毁灭", "魔气滔天", "黑暗笼罩"]},
    {"sub": "轮回", "acts": ["感悟轮回", "超脱轮回", "送人往生", "逆转轮回", "轮回轮转", "宿命循环"]},
    {"sub":  "造化之力", "acts": ["掌握造化", "融合精髓", "以造化生", "观摩奇迹", "造化神奇", "生机盎然"]},
    {"sub": "混沌之气", "acts":  ["吞噬混沌", "以混沌铸", "感悟真意", "驾驭混沌", "混沌未开", "鸿蒙初分"]},
    {"sub": "永恒不朽", "acts": ["铸就不朽", "感受境界", "吞噬血质", "融合不朽", "不朽之躯", "永恒闪烁"]},
    {"sub": "诸天星辰", "acts": ["汲取精华", "引星入体", "观星象悟", "镇压星辰", "星光璀璨", "繁星满天"]},
]

PREFIX_HIGH = [
    "太古", "虚空", "天道", "混沌", "不朽", "灭世", "真龙", "星辰",
    "鸿蒙", "永恒", "无极", "至高", "绝世", "造化", "超越", "无敌",
    "逆天", "震撼", "煌煌", "璀璨"
]

# ==========================================
# 3. B 选项专用词库 - 全四字短语
# ==========================================

ACTION_B_LEAVE = {
    "low": [
        "置之不理", "转身离开", "绕路而行", "弃而远之", "视若无睹",
        "悄悄退去", "假装未见", "默默离开", "闭目不看", "形同陌路",
        "匆匆而过", "装作害怕", "不敢靠近", "远远观望"
    ],
    "mid":  [
        "谨慎退去", "不沾因果", "远观其变", "转身离开", "敬而远之",
        "按捺好奇", "理性克制", "深思熟虑", "权衡利弊", "不敢冒险",
        "静观其变", "暂时回避", "留待来日", "避而远之"
    ],
    "high": [
        "不敢染指", "敬而远之", "迅速遁走", "避开因果", "隐身躲避",
        "不与其争", "避世潜行", "顺其自然", "不强求缘", "超然物外",
        "顺道而行", "闭目养神", "冥想规避", "以退为进"
    ]
}

ACTION_B_SAFE = {
    "low": [
        "小心吸纳", "缓慢修炼", "浅尝即止", "静心观察", "谨慎品尝",
        "循序渐进", "循旧悟新", "安全采集", "一步步来", "打好基础",
        "稳扎稳打", "保持谨慎", "小口小口", "细细感受"
    ],
    "mid": [
        "稳固修为", "以稳为主", "温养灵气", "坐观其变", "厚积薄发",
        "循序渐进", "沉心静气", "蓄势待发", "打磨基础", "稳健进阶",
        "控制火候", "缓缓吸纳", "安全第一", "夯实根基"
    ],
    "high": [
        "顺势感悟", "借势修行", "以道御力", "在此盘桓", "感悟不贪",
        "制衡其力", "智慧运用", "循道而行", "借力而行", "以柔克刚",
        "道法自然", "不贪不躁", "静水深流", "驭势成仙"
    ]
}

ACTION_B_FIGHT = {
    "low": [
        "强行突围", "决然拒绝", "拼死一搏", "死战不退", "全力反抗",
        "奋起反抗", "破釜沉舟", "舍身忘死", "誓死抵抗", "绝不退缩",
        "殊死搏斗", "宁死不屈", "奋力抵抗", "寸土不让"
    ],
    "mid": [
        "祭出法宝", "与其斗法", "绝不妥协", "全力对抗", "激烈交手",
        "不惧敌手", "决一死战", "展开大战", "法宝对轰", "剑气纵横",
        "激烈碰撞", "势均力敌", "各展神通", "拼尽全力"
    ],
    "high": [
        "破碎虚空", "逆天而行", "以此证道", "翻天覆地", "搅动风云",
        "天地变色", "大道交锋", "星辰陨落", "混沌初开", "诸天轰鸣",
        "逆伐苍天", "寂灭之战", "永恒之争", "终极对决"
    ]
}

# ==========================================
# 4. 模板配置
# ==========================================
EVENT_TEMPLATES = [
    {
        "type": "pure_gain",
        "desc_suffix": " 机缘已至。",
        "choice_a_logic": "gain_standard",
        "choice_b_logic": "nothing"
    },
    {
        "type": "risk_reward",
        "desc_suffix":  " 福祸相依。",
        "choice_a_logic": "gamble_qi",
        "choice_b_logic": "nothing"
    },
    {
        "type":  "buff_gamble",
        "desc_suffix": " 福祸相依。",
        "choice_a_logic": "gamble_buff_auto",
        "choice_b_logic": "gain_auto_safe"
    },
    {
        "type": "item_reward",
        "desc_suffix":  " 似有宝光。",
        "choice_a_logic": "grant_item",
        "choice_b_logic": "nothing"
    },
    {
        "type": "trade_loss",
        "desc_suffix":  " 需付出代价。",
        "choice_a_logic": "pay_qi",
        "choice_b_logic": "gamble_qi"
    }
]

# ==========================================
# 5. 核心逻辑函数
# ==========================================

def get_title_and_action_a(stage_idx):
    """生成标题、描述主体、和选项A"""
    if stage_idx <= 3:
        item = random.choice(DATA_LOW)
        prefix = random.choice(PREFIX_LOW)
        title = f"{prefix}{item['sub']}"
        desc = f"偶遇{title}。"
        act_a = random.choice(item['acts'])
    elif stage_idx <= 9:
        item = random.choice(DATA_MID)
        prefix = random.choice(PREFIX_MID)
        title = f"{prefix}{item['sub']}"
        desc = f"发现{title}。"
        act_a = random.choice(item['acts'])
    else:
        item = random.choice(DATA_HIGH)
        prefix = random.choice(PREFIX_HIGH)
        title = f"{prefix}{item['sub']}"
        desc = f"触碰{title}。"
        act_a = random.choice(item['acts'])
    
    return title, desc, act_a

def get_action_b_text(logic_type, stage_idx):
    """根据 B 的逻辑选择正确的文案"""
    
    if stage_idx <= 3:
        level_key = "low"
    elif stage_idx <= 9:
        level_key = "mid"
    else:
        level_key = "high"
    
    if logic_type == "nothing":
        return random.choice(ACTION_B_LEAVE[level_key])
        
    if logic_type in ["gain_auto_safe", "gain_tap_safe"]:
        return random.choice(ACTION_B_SAFE[level_key])
        
    if logic_type == "gamble_qi":
        return random.choice(ACTION_B_FIGHT[level_key])
        
    return "尝试一下"

def calculate_qi_gain(stage_idx):
    """计算灵气收益"""
    if stage_idx <= 3:
        base = 120
        growth = 1.6
    elif stage_idx <= 9:
        base = 500
        growth = 1.9
    else:
        base = 8000
        growth = 2.4
    
    val = base * math.pow(growth, stage_idx)
    final_val = int(val * random.uniform(0.8, 1.2))
    
    if final_val > 10000:
        return (final_val // 100) * 100
    return (final_val // 10) * 10

def build_effect(logic_type, qi_base, stage_idx):
    """构建效果"""
    if logic_type == "nothing":
        return {"type": "nothing"}
    if logic_type == "gain_standard":
        return {"type": "gain_qi", "value": qi_base}
    if logic_type == "gamble_qi":
        return {"type":  "gamble", "value": qi_base}
    if logic_type == "pay_qi":
        return {"type": "lose_qi", "value": int(qi_base * 0.5)}
    if logic_type == "grant_item":
        return {"type": "grant_item", "value": None}
    
    if logic_type == "gain_auto_safe":
        return {"type": "gain_auto_temp", "value": 0.5, "duration": 60}
    if logic_type == "gain_tap_safe":
        return {"type": "gain_tap_ratio_temp", "value": 0.5, "duration": 60}
    
    if logic_type == "gamble_buff_auto":
        duration = 60 if stage_idx < 10 else 120
        bonus = 2.0 if stage_idx < 10 else 3.0
        return {"type":  "gamble_auto", "value": bonus, "duration": duration}
    if logic_type == "gamble_buff_tap":
        duration = 30 if stage_idx < 10 else 60
        return {"type": "gamble_tap", "value": 3.0, "duration": duration}
        
    return {"type": "nothing"}

def polish_choice_text(text, logic_type):
#    """最后的修饰"""
#    if logic_type == "gamble_qi":
#        return f"{text} (博)"
#    if logic_type == "gamble_buff_auto" or logic_type == "gamble_buff_tap":
#        return f"{text} (吞)"
#    if logic_type == "grant_item":
#        return f"{text} (夺)"
#    if logic_type == "pay_qi":
#        return f"{text} (财)"
#    
#    if logic_type in ["gain_auto_safe", "gain_tap_safe"]:
#        return f"{text} (稳)"
        
    return text

def get_weights_by_stage(stage_idx):
    """根据段位调整事件模板比例"""
    if stage_idx <= 3:
        return [40, 10, 40, 5, 5]
    elif stage_idx <= 9:
        return [40, 20, 20, 15, 5]
    else:
        return [25, 30, 10, 25, 10]

# ==========================================
# 6. 主生成循环
# ==========================================

events = []
global_id_counter = 1

print("🔥 开始生成修仙事件 (四字短语版)...")
print("📚 特性：古韵十足、四字短语、意蕴深远\n")

for stage_idx in range(16):
    if stage_idx <= 3:
        count = 50
    elif stage_idx <= 7:
        count = 100
    elif stage_idx <= 11:
        count = 150
    else:
        count = 200
        
    current_stage_name = STAGES[stage_idx]
    
    for _ in range(count):
        weights = get_weights_by_stage(stage_idx)
        template = random.choices(EVENT_TEMPLATES, weights=weights, k=1)[0]
        
        logic_a = template["choice_a_logic"]
        logic_b = template["choice_b_logic"]
        suffix = template["desc_suffix"]
        
        if template["type"] == "buff_gamble":
            if random.random() < 0.5:
                logic_a = "gamble_buff_tap"
                logic_b = "gain_tap_safe"
                suffix = " 心血来潮！"
        
        title, desc_base, btn_a_raw = get_title_and_action_a(stage_idx)
        full_desc = desc_base + suffix
        qi_val = calculate_qi_gain(stage_idx)
        
        btn_b_raw = get_action_b_text(logic_b, stage_idx)
        
        effect_a = build_effect(logic_a, qi_val, stage_idx)
        effect_b = build_effect(logic_b, qi_val, stage_idx)
        
        btn_a_final = polish_choice_text(btn_a_raw, logic_a)
        btn_b_final = polish_choice_text(btn_b_raw, logic_b)
        
        event = {
            "id": f"evt_4char_{global_id_counter:05d}",
            "title": title,
            "desc": full_desc,
            "rarity": "epic" if stage_idx >= 10 else ("rare" if stage_idx >= 5 else "common"),
            "minStage":  STAGES[stage_idx],
            "maxStage": STAGES[min(stage_idx + 2, 15)],
            "choices": [
                { "id": "a", "text": btn_a_final, "effect": effect_a },
                { "id": "b", "text": btn_b_final, "effect": effect_b }
            ]
        }
        
        events.append(event)
        global_id_counter += 1
    
    print(" ✓")

file_path = "events_four_char.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"\n✅ [四字短语版] 生成完毕！")
print(f"📊 总计生成 {len(events)} 个修仙事件")
print(f"📁 已保存至:  {file_path}")
print(f"\n🎯 核心特点：")
print(f"   ✨ 所有动作均为四字短语或对仗格式")
print(f"   ✨ 古韵十足，符合修仙小说气质")
print(f"   ✨ B选项有14种选择，全为四字短语")
print(f"   ✨ 文案简洁有力，朗朗上口")
print(f"   ✨ 段位差异明显，层次递进感强")
