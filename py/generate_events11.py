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
# 2. 文案库 (Subject -> Action A 绑定)
# ==========================================
DATA_LOW = [
    {"sub": "灵泉", "acts": ["痛饮", "装瓶", "沐浴", "感悟"]},
    {"sub": "石碑", "acts": ["拓印", "参悟", "抚摸", "清理"]},
    {"sub": "野兽", "acts": ["击杀", "驱赶", "剥皮", "取丹"]},
    {"sub": "灵草", "acts": ["采摘", "移植", "吞服", "守护"]},
    {"sub": "洞府", "acts": ["探索", "搜刮", "打坐", "在此休息"]},
    {"sub": "行脚商", "acts": ["交易", "攀谈", "打劫", "求购"]},
    {"sub": "猎户", "acts": ["帮助", "指路", "施舍", "救治"]},
    {"sub": "野果", "acts": ["食用", "采摘", "酿酒", "收藏"]},
    {"sub": "寒潭", "acts": ["淬体", "潜入", "取水", "修炼"]},
    {"sub": "残剑", "acts": ["拾取", "擦拭", "感悟剑意", "重铸"]}
]
PREFIX_LOW = ["残破的", "普通的", "路边的", "山间的", "神秘的", "微弱的", "凡尘的", "荒废的", "古老的"]

DATA_MID = [
    {"sub": "秘境", "acts": ["闯入", "探索", "寻找阵眼", "在此感悟"]},
    {"sub": "长老", "acts": ["请教", "论道", "切磋", "拜访"]},
    {"sub": "妖兽", "acts": ["斩杀证道", "降伏", "取其妖丹", "炼化血肉"]},
    {"sub": "灵脉", "acts": ["吸纳", "截取", "在此开辟洞府", "布阵"]},
    {"sub": "雷劫", "acts": ["引雷淬体", "硬抗", "感悟雷法", "收集雷液"]},
    {"sub": "心魔", "acts": ["坚守道心", "斩杀", "炼化", "无视"]},
    {"sub": "阵法", "acts": ["破阵", "参悟", "掌控", "修补"]},
    {"sub": "丹炉", "acts": ["开炉", "温养", "取丹", "炼制"]},
    {"sub": "残魂", "acts": ["搜魂", "超度", "吞噬", "询问"]},
    {"sub": "剑意", "acts": ["观摩", "融合", "对抗", "收服"]}
]
PREFIX_MID = ["上古", "宗门", "千年", "狂暴的", "奇异的", "禁制的", "魔化的", "纯净的", "雷霆"]

DATA_HIGH = [
    {"sub": "虚空裂缝", "acts": ["汲取能量", "封印", "探索", "肉身横渡"]},
    {"sub": "法则碎片", "acts": ["融合", "感悟", "铭刻", "吞噬"]},
    {"sub": "灭世神雷", "acts": ["硬抗天威", "炼入法宝", "以身试法", "吸收"]},
    {"sub": "仙人遗蜕", "acts": ["祭拜", "搜身", "感悟仙韵", "埋葬"]},
    {"sub": "时光长河", "acts": ["逆流而上", "观摩岁月", "捞取未来", "斩断过去"]},
    {"sub": "世界本源", "acts": ["炼化", "融合", "守护", "窃取"]},
    {"sub": "太古古神", "acts": ["论道", "挑战", "聆听教诲", "观察"]},
    {"sub": "仙宫", "acts": ["入主", "镇压", "开启", "重建"]},
    {"sub": "域外魔域", "acts": ["杀进去", "封印入口", "炼化魔气", "毁灭"]},
    {"sub": "轮回", "acts": ["感悟轮回", "超脱", "送人往生", "逆转"]}
]
PREFIX_HIGH = ["太古", "虚空", "天道", "混沌", "不朽", "灭世", "真龙", "星辰", "鸿蒙"]

# ==========================================
# 3. 🆕 B 选项专用词库 (逻辑强绑定)
# ==========================================

# 对应 logic == "nothing" (放弃/离开)
ACTION_B_LEAVE = {
    "low": ["无视", "离开", "绕路", "放弃", "不予理会"],
    "mid": ["谨慎退去", "不沾因果", "远远观望", "转身离开"],
    "high": ["不敢染指", "敬而远之", "迅速遁走", "避开因果"]
}

# 对应 logic in ["gain_auto_safe", "gain_tap_safe"] (稳健收益)
ACTION_B_SAFE = {
    "low": ["小心吸纳", "缓慢修炼", "浅尝即止", "静心观察"],
    "mid": ["稳固修为", "以稳为主", "温养灵气", "坐观其变"],
    "high": ["顺势感悟", "借势修行", "以道御力", "在此盘桓"]
}

# 对应 logic == "gamble_qi" (在破财模板中，B选项是反抗)
ACTION_B_FIGHT = {
    "low": ["强行突围", "拒绝", "拼死一搏"],
    "mid": ["祭出法宝", "与其斗法", "绝不妥协"],
    "high": ["破碎虚空", "逆天而行", "以此证道"]
}

# ==========================================
# 4. 模板配置
# ==========================================
EVENT_TEMPLATES = [
    {   # Index 0: 纯灵气
        "type": "pure_gain",
        "desc_suffix": " 机缘已至。",
        "choice_a_logic": "gain_standard",
        "choice_b_logic": "nothing"
    },
    {   # Index 1: 赌灵气
        "type": "risk_reward",
        "desc_suffix": " 福祸相依。",
        "choice_a_logic": "gamble_qi",
        "choice_b_logic": "nothing"
    },
    {   # Index 2: 赌 Buff
        "type": "buff_gamble",
        "desc_suffix": " 成败一念。",
        "choice_a_logic": "gamble_buff_auto",
        "choice_b_logic": "gain_auto_safe" # 这里会匹配到 ACTION_B_SAFE
    },
    {   # Index 3: 道具
        "type": "item_reward",
        "desc_suffix": " 似有宝光。",
        "choice_a_logic": "grant_item",
        "choice_b_logic": "nothing"
    },
    {   # Index 4: 破财免灾
        "type": "trade_loss",
        "desc_suffix": " 需付出代价。",
        "choice_a_logic": "pay_qi",
        "choice_b_logic": "gamble_qi" # 这里会匹配到 ACTION_B_FIGHT
    }
]

# ==========================================
# 5. 核心逻辑函数
# ==========================================

def get_title_and_action_a(stage_idx):
    """生成标题、描述主体、和选项A(基于主语)"""
    if stage_idx <= 3:
        item = random.choice(DATA_LOW); prefix = random.choice(PREFIX_LOW)
        title = f"{prefix}{item['sub']}"; desc = f"偶遇{title}。"
        act_a = random.choice(item['acts'])
    elif stage_idx <= 9:
        item = random.choice(DATA_MID); prefix = random.choice(PREFIX_MID)
        title = f"{prefix}{item['sub']}"; desc = f"发现{title}。"
        act_a = random.choice(item['acts'])
    else:
        item = random.choice(DATA_HIGH); prefix = random.choice(PREFIX_HIGH)
        title = f"{prefix}{item['sub']}"; desc = f"触碰{title}。"
        act_a = random.choice(item['acts'])
    return title, desc, act_a

def get_action_b_text(logic_type, stage_idx):
    """🔥 核心：根据 B 的逻辑选择正确的文案"""
    
    # 确定等级 Key
    if stage_idx <= 3: level_key = "low"
    elif stage_idx <= 9: level_key = "mid"
    else: level_key = "high"
    
    # 1. 离开类 (nothing)
    if logic_type == "nothing":
        return random.choice(ACTION_B_LEAVE[level_key])
        
    # 2. 稳健收益类 (safe buff)
    if logic_type in ["gain_auto_safe", "gain_tap_safe"]:
        return random.choice(ACTION_B_SAFE[level_key])
        
    # 3. 博弈反抗类 (gamble) - 对应破财模板的 B 选项
    if logic_type == "gamble_qi":
        return random.choice(ACTION_B_FIGHT[level_key])
        
    return "尝试一下" # 兜底

def calculate_qi_gain(stage_idx):
    if stage_idx <= 3: base = 120; growth = 1.6
    elif stage_idx <= 9: base = 500; growth = 1.9
    else: base = 8000; growth = 2.4
    val = base * math.pow(growth, stage_idx)
    final_val = int(val * random.uniform(0.8, 1.2))
    if final_val > 10000: return (final_val // 100) * 100
    return (final_val // 10) * 10

def build_effect(logic_type, qi_base, stage_idx):
    if logic_type == "nothing": return {"type": "nothing"}
    if logic_type == "gain_standard": return {"type": "gain_qi", "value": qi_base}
    if logic_type == "gamble_qi": return {"type": "gamble", "value": qi_base}
    if logic_type == "pay_qi": return {"type": "lose_qi", "value": int(qi_base * 0.5)}
    if logic_type == "grant_item": return {"type": "grant_item", "value": None}
    
    # 稳健 Buff
    if logic_type == "gain_auto_safe": return {"type": "gain_auto_temp", "value": 0.5, "duration": 60}
    if logic_type == "gain_tap_safe": return {"type": "gain_tap_ratio_temp", "value": 0.5, "duration": 60}
    
    # 激进 Buff
    if logic_type == "gamble_buff_auto":
        duration = 60 if stage_idx < 10 else 120
        bonus = 2.0 if stage_idx < 10 else 3.0
        return {"type": "gamble_auto", "value": bonus, "duration": duration}
    if logic_type == "gamble_buff_tap":
        duration = 30 if stage_idx < 10 else 60
        return {"type": "gamble_tap", "value": 3.0, "duration": duration}
        
    return {"type": "nothing"}

def polish_choice_text(text, logic_type):
#    """最后的修饰：主要处理固定格式的A选项"""
#    if logic_type == "gamble_qi": return f"{text} (博)"
#    if logic_type == "gamble_buff_auto" or logic_type == "gamble_buff_tap": return f"{text} (吞服)"
#    if logic_type == "grant_item": return f"{text} (夺宝)"
#    if logic_type == "pay_qi": return f"{text} (破财)"
#    
#    # 注意：B 选项的 "稳健" 后缀其实在 get_action_b_text 选词时已经隐含了意思
#    # 这里可以不加，保持清爽，或者加一个 (稳)
#    if logic_type in ["gain_auto_safe", "gain_tap_safe"]:
#        return f"{text} (稳)"
        
    return text

def get_weights_by_stage(stage_idx):
    if stage_idx <= 3: return [40, 10, 40, 5, 5]
    elif stage_idx <= 9: return [40, 20, 20, 15, 5]
    else: return [25, 30, 10, 25, 10]

# ==========================================
# 6. 主生成循环
# ==========================================

events = []
global_id_counter = 1

print("🔥 开始生成修仙事件 (智能文案版)...")

for stage_idx in range(16):
    if stage_idx <= 3: count = 50
    elif stage_idx <= 7: count = 100
    elif stage_idx <= 11: count = 150
    else: count = 200
        
    current_stage_name = STAGES[stage_idx]
    
    for _ in range(count):
        weights = get_weights_by_stage(stage_idx)
        template = random.choices(EVENT_TEMPLATES, weights=weights, k=1)[0]
        
        logic_a = template["choice_a_logic"]
        logic_b = template["choice_b_logic"]
        suffix = template["desc_suffix"]
        
        # 动态切换 Auto/Tap 赌局
        if template["type"] == "buff_gamble":
            if random.random() < 0.5:
                logic_a = "gamble_buff_tap"
                logic_b = "gain_tap_safe" # 对应的稳健选项
                suffix = " 心血来潮！"
        
        # 1. 生成标题、描述、选项A (基于主语)
        title, desc_base, btn_a_raw = get_title_and_action_a(stage_idx)
        full_desc = desc_base + suffix
        qi_val = calculate_qi_gain(stage_idx)
        
        # 2. 生成选项B (基于逻辑！！！)
        btn_b_raw = get_action_b_text(logic_b, stage_idx)
        
        # 3. 构建效果
        effect_a = build_effect(logic_a, qi_val, stage_idx)
        effect_b = build_effect(logic_b, qi_val, stage_idx)
        
        # 4. 最终润色 (加后缀)
        btn_a_final = polish_choice_text(btn_a_raw, logic_a)
        # B 选项因为是专门选的词，通常不需要加 (稳) 后缀也行，或者加上统一风格
        btn_b_final = polish_choice_text(btn_b_raw, logic_b)
        
        event = {
            "id": f"evt_smart_{global_id_counter:05d}",
            "title": title,
            "desc": full_desc,
            "rarity": "epic" if stage_idx >= 10 else ("rare" if stage_idx >= 5 else "common"),
            "minStage": STAGES[stage_idx],
            "maxStage": STAGES[min(stage_idx + 2, 15)],
            "choices": [
                { "id": "a", "text": btn_a_final, "effect": effect_a },
                { "id": "b", "text": btn_b_final, "effect": effect_b }
            ]
        }
        
        events.append(event)
        global_id_counter += 1

file_path = "events.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"\n✅ [智能文案版] 生成完毕！Choice B 的文案现在完美匹配逻辑了。")
