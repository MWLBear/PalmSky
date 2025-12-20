import json
import random
import math

# --- 1. 基础配置 ---
TOTAL_EVENTS = 600

# 16 大境界
STAGES = [
    "筑基", "开光", "胎息", "辟谷",
    "金丹", "元婴", "出窍", "分神",
    "合体", "大乘", "渡劫", "地仙",
    "天仙", "金仙", "大罗金仙", "九天玄仙"
]

# --- 2. 文案词库 (保持短小精悍) ---
# 前期 (0-3)
PREFIX_LOW = ["残破", "普通", "路边", "山间", "神秘", "微弱", "凡尘", "荒废", "古老"]
SUBJECT_LOW = ["灵泉", "石碑", "野兽", "灵草", "洞府", "行脚商", "猎户", "野果", "寒潭", "断剑"]
ACTION_LOW_A = ["取走", "感悟", "击杀", "采集", "探索", "交易", "帮助", "食用", "清洗", "拾取"]
ACTION_LOW_B = ["无视", "离开", "绕路", "放弃", "不予理会"]

# 中期 (4-9)
PREFIX_MID = ["上古", "宗门", "千年", "狂暴", "奇异", "禁制", "魔化", "纯净", "雷霆"]
SUBJECT_MID = ["秘境", "长老", "妖兽", "灵脉", "雷劫", "心魔", "阵法", "丹炉", "残魂", "剑意"]
ACTION_MID_A = ["破除", "请教", "斩杀", "吸纳", "淬体", "坚守", "参悟", "炼丹", "搜魂", "观摩"]

# 后期 (10-15)
PREFIX_HIGH = ["太古", "虚空", "天道", "混沌", "不朽", "灭世", "真龙", "星辰", "法则", "鸿蒙"]
SUBJECT_HIGH = ["裂缝", "法则", "神雷", "遗蜕", "长河", "本源", "古神", "仙宫", "魔域", "轮回"]
ACTION_HIGH_A = ["合道", "吞噬", "抗天", "祭拜", "逆流", "炼化", "论道", "入主", "镇压", "斩断"]

# --- 3. ⌚️ Watch优化：极简模板 ---
EVENT_TEMPLATES = [
    {
        "type": "pure_gain",
        "weight": 50,
        "desc_suffix": " 机缘已至。", # 极简文案
        "choice_a_logic": "gain_standard",
        "choice_b_logic": "nothing"
    },
    {
        "type": "risk_reward",
        "weight": 30,
        "desc_suffix": " 福祸相依。", # 极简文案
        "choice_a_logic": "gain_or_lose",
        "choice_b_logic": "nothing"
    },
    {
        "type": "buff_time",
        "weight": 20,
        "desc_suffix": " 稍纵即逝！", # 强调紧迫感
        "choice_a_logic": "buff_auto",
        "choice_b_logic": "gain_tap_buff"
    }
]

# --- 4. 辅助函数 ---

def get_random_text(stage_idx):
    """⌚️ Watch优化：生成极短的描述"""
    if stage_idx <= 3:
        title = f"{random.choice(PREFIX_LOW)}{random.choice(SUBJECT_LOW)}"
        # "偶遇[残破灵泉]。" (6-8字)
        base_desc = f"偶遇{title}。"
        a = random.choice(ACTION_LOW_A)
        b = random.choice(ACTION_LOW_B)
    elif stage_idx <= 9:
        title = f"{random.choice(PREFIX_MID)}{random.choice(SUBJECT_MID)}"
        # "前方出现[上古秘境]。" (8-10字)
        base_desc = f"前方出现{title}。"
        a = random.choice(ACTION_MID_A)
        b = random.choice(ACTION_LOW_B)
    else:
        title = f"{random.choice(PREFIX_HIGH)}{random.choice(SUBJECT_HIGH)}"
        # "触碰到了[太古裂缝]。" (8-10字)
        base_desc = f"触碰到了{title}。"
        a = random.choice(ACTION_HIGH_A)
        b = "不敢染指"
    return title, base_desc, a, b

def calculate_qi_gain(stage_idx):
    """数值膨胀公式 (保持不变，符合1年规划)"""
    if stage_idx <= 3:
        base = 120; growth = 1.6
    elif stage_idx <= 9:
        base = 500; growth = 1.9
    else:
        base = 8000; growth = 2.4

    val = base * math.pow(growth, stage_idx)
    random_factor = random.uniform(0.8, 1.2)
    final_val = int(val * random_factor)
    
    if final_val > 10000:
        return (final_val // 100) * 100
    return (final_val // 10) * 10

def build_effect(logic_type, qi_base, stage_idx):
    """⌚️ Watch优化：Buff 时间缩短，数值增强"""
    if logic_type == "nothing":
        return {"type": "nothing"}
        
    if logic_type == "gain_standard":
        return {"type": "gain_qi", "value": qi_base}
        
    if logic_type == "gain_or_lose":
        # 60% 赢，40% 输一半
        if random.random() < 0.6:
            return {"type": "gain_qi", "value": qi_base}
        else:
            return {"type": "lose_qi", "value": int(qi_base * 0.5)}
            
    if logic_type == "buff_auto":
        # ⌚️ Watch优化: 60秒 / 120秒 (短平快)
        # 自动收益加成提升到 0.8 / 1.0 (因为时间短了，效果要猛)
        duration = 60 if stage_idx < 10 else 120
        value = 0.8 if stage_idx < 10 else 1.0
        return {"type": "gain_auto_temp", "value": value, "duration": duration}
        
    if logic_type == "gain_tap_buff":
        # ⌚️ Watch优化: 30秒 / 60秒 (极速连点)
        if stage_idx >= 5:
            duration = 30 if stage_idx < 10 else 60
            return {"type": "gain_tap_ratio_temp", "value": 1.5, "duration": duration}
        else:
            return {"type": "nothing"}

    return {"type": "nothing"}

def polish_choice_text(text, logic_type):
    """⌚️ Watch优化：选项文字极简"""
    if logic_type == "gain_or_lose":
        return f"{text} (博)"
    if logic_type == "buff_auto" or logic_type == "gain_tap_buff":
        return f"{text} (增益)"
    return text

# --- 5. 主生成循环 ---

events = []

for i in range(TOTAL_EVENTS):
    target_stage_idx = random.randint(0, 15)
    
    # 权重调整：减少极端事件，增加爽感
    if target_stage_idx >= 10:
        weights = [40, 40, 20]
    else:
        weights = [60, 30, 10]
        
    template = random.choices(EVENT_TEMPLATES, weights=weights, k=1)[0]
    
    title, desc_base, btn_a_raw, btn_b_raw = get_random_text(target_stage_idx)
    
    # 拼接描述
    full_desc = desc_base + template["desc_suffix"]
    
    qi_val = calculate_qi_gain(target_stage_idx)
    effect_a = build_effect(template["choice_a_logic"], qi_val, target_stage_idx)
    effect_b = build_effect(template["choice_b_logic"], qi_val, target_stage_idx)
    
    btn_a_final = polish_choice_text(btn_a_raw, template["choice_a_logic"])
    btn_b_final = polish_choice_text(btn_b_raw, template["choice_b_logic"])
    
    event = {
        "id": f"evt_watch_{i+1:04d}", # ID 标识改变
        "title": title,
        "desc": full_desc,
        "rarity": "epic" if target_stage_idx >= 10 else ("rare" if target_stage_idx >= 5 else "common"),
        "minStage": STAGES[target_stage_idx],
        "maxStage": STAGES[min(target_stage_idx + 2, 15)],
        "choices": [
            { "id": "a", "text": btn_a_final, "effect": effect_a },
            { "id": "b", "text": btn_b_final, "effect": effect_b }
        ]
    }
    
    events.append(event)

# --- 6. 写入文件 ---
file_path = "events.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"✅ [Watch优化版] 生成完毕！共 {len(events)} 个事件。")
