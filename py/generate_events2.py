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

# --- 2. 文案词库 ---
# 前期 (0-3)
PREFIX_LOW = ["残破的", "普通的", "路边的", "山间的", "神秘的", "微弱的", "凡尘的", "荒废的", "古老的"]
SUBJECT_LOW = ["灵泉", "石碑", "野兽", "灵草", "洞府", "行脚商", "猎户", "野果", "寒潭", "断剑", "手札"]
ACTION_LOW_A = ["取走", "感悟", "击杀", "采集", "探索", "交易", "帮助", "食用", "清洗", "拾取"]
ACTION_LOW_B = ["无视", "离开", "绕路", "放弃", "不予理会", "谨慎观望"]

# 中期 (4-9)
PREFIX_MID = ["上古", "宗门", "千年", "狂暴的", "奇异的", "禁制的", "魔化的", "纯净的", "雷霆"]
SUBJECT_MID = ["秘境", "长老", "妖兽", "灵脉", "雷劫", "心魔", "阵法", "丹炉", "残魂", "剑意", "异火"]
ACTION_MID_A = ["强行破除", "虚心请教", "斩杀证道", "吸纳灵气", "引雷淬体", "坚守道心", "入阵参悟", "开炉炼丹", "搜魂", "观摩"]

# 后期 (10-15)
PREFIX_HIGH = ["太古", "虚空", "天道", "混沌", "不朽", "灭世", "真龙", "星辰", "法则", "鸿蒙", "因果"]
SUBJECT_HIGH = ["裂缝", "法则", "神雷", "遗蜕", "长河", "本源", "古神", "仙宫", "魔域", "轮回", "界碑"]
ACTION_HIGH_A = ["以身合道", "吞噬本源", "硬抗天威", "祭拜", "逆流而上", "炼化", "论道", "入主", "镇压", "斩断"]

# --- 3. 核心优化：事件模板 ---
# 决定了事件的“玩法结构”
EVENT_TEMPLATES = [
    {
        "type": "pure_gain",
        "weight": 40, # 出现权重
        "desc_suffix": "这似乎是一场机缘。",
        "choice_a_logic": "gain_standard",
        "choice_b_logic": "nothing"
    },
    {
        "type": "risk_reward",
        "weight": 30,
        "desc_suffix": "但其中隐约透着一丝凶险。",
        "choice_a_logic": "gain_or_lose", # 60% 赢，40% 输
        "choice_b_logic": "nothing"
    },
    {
        "type": "high_stakes",
        "weight": 15,
        "desc_suffix": "这是逆天改命的机会，也伴随着陨落的风险。",
        "choice_a_logic": "gamble_big", # 50% 暴富，50% 血亏
        "choice_b_logic": "gain_safe"   # 拿低保走人
    },
    {
        "type": "buff_time",
        "weight": 15,
        "desc_suffix": "这种感悟转瞬即逝，需抓紧时间。",
        "choice_a_logic": "buff_auto", # 获得自动收益 Buff
        "choice_b_logic": "gain_tap_buff" # 获得点击收益 Buff (或者 nothing)
    }
]

# --- 4. 辅助函数 ---

def get_random_text(stage_idx):
    """根据境界生成基础文案"""
    if stage_idx <= 3:
        title = f"{random.choice(PREFIX_LOW)}{random.choice(SUBJECT_LOW)}"
        base_desc = f"游历途中，偶然发现了{title}。"
        a = random.choice(ACTION_LOW_A)
        b = random.choice(ACTION_LOW_B)
    elif stage_idx <= 9:
        title = f"{random.choice(PREFIX_MID)}{random.choice(SUBJECT_MID)}"
        base_desc = f"感应到前方有{title}出世，散发着惊人的波动。"
        a = random.choice(ACTION_MID_A)
        b = random.choice(ACTION_LOW_B)
    else:
        title = f"{random.choice(PREFIX_HIGH)}{random.choice(SUBJECT_HIGH)}"
        base_desc = f"触碰到了{title}的气息，这是通往大道的契机。"
        a = random.choice(ACTION_HIGH_A)
        b = "不敢染指"
    return title, base_desc, a, b

def calculate_qi_gain(stage_idx):
    """
    分段指数增长公式
    解决后期数值不够爆炸的问题
    """
    if stage_idx <= 3:       # 前期 (筑基-辟谷)
        base = 120
        growth = 1.6
    elif stage_idx <= 9:     # 中期 (金丹-大乘)
        base = 500
        growth = 1.9         # 提升斜率
    else:                    # 后期 (渡劫-玄仙)
        base = 8000          # 基础值跃迁
        growth = 2.4         # 爆炸性增长

    val = base * math.pow(growth, stage_idx)
    
    # 随机波动 ±25%
    random_factor = random.uniform(0.75, 1.25)
    final_val = int(val * random_factor)
    
    # 取整
    if final_val > 10000:
        return (final_val // 100) * 100
    return (final_val // 10) * 10

def build_effect(logic_type, qi_base, stage_idx):
    """
    效果工厂：根据逻辑类型生成具体的 Effect JSON
    """
    if logic_type == "nothing":
        return {"type": "nothing"}
        
    if logic_type == "gain_standard":
        return {"type": "gain_qi", "value": qi_base}
        
    if logic_type == "gain_safe":
        # 低保：只有基础值的 30%
        return {"type": "gain_qi", "value": int(qi_base * 0.3)}
        
    if logic_type == "gain_or_lose":
        # 风险：60% 几率获得 100%，40% 几率扣除 50%
        if random.random() < 0.6:
            return {"type": "gain_qi", "value": qi_base}
        else:
            return {"type": "lose_qi", "value": int(qi_base * 0.5)}
            
    if logic_type == "gamble_big":
        # 赌狗：50% 几率获得 250%，50% 几率扣除 100% (甚至更多)
        if random.random() < 0.5:
            return {"type": "gain_qi", "value": int(qi_base * 2.5)}
        else:
            return {"type": "lose_qi", "value": qi_base}
            
    if logic_type == "buff_auto":
        # 自动收益加成
        duration = 300 if stage_idx < 10 else 600
        return {"type": "gain_auto_temp", "value": 0.5, "duration": duration}
        
    if logic_type == "gain_tap_buff":
        # 点击收益加成 (后期才给)
        if stage_idx >= 5:
            return {"type": "gain_tap_ratio_temp", "value": 1.0, "duration": 120}
        else:
            return {"type": "nothing"} # 前期给个空，引导玩家选 A

    return {"type": "nothing"}

def polish_choice_text(text, logic_type):
    """文案润色：暗示风险"""
    if logic_type == "gamble_big":
        return f"{text} (险中求富)"
    if logic_type == "gain_safe":
        return f"{text} (稳妥)"
    if logic_type == "gain_or_lose":
        return f"{text} (一试)"
    return text

# --- 5. 主生成循环 ---

events = []

for i in range(TOTAL_EVENTS):
    # 1. 随机境界 (加权随机，让中期事件稍微多一点，因为玩家中期停留时间长)
    # 简单起见，这里先均匀分布，后期可调
    target_stage_idx = random.randint(0, 15)
    
    # 2. 随机选择模板 (根据权重)
    # 境界越高，越容易出现高风险高回报的事件
    if target_stage_idx >= 10:
        # 后期：降低纯收益，提高赌狗权重
        weights = [20, 30, 30, 20]
    else:
        # 前期：主要是送福利
        weights = [50, 30, 10, 10]
        
    template = random.choices(EVENT_TEMPLATES, weights=weights, k=1)[0]
    
    # 3. 生成基础信息
    title, desc_base, btn_a_raw, btn_b_raw = get_random_text(target_stage_idx)
    
    # 拼接描述
    full_desc = desc_base + template["desc_suffix"]
    
    # 4. 计算数值基准
    qi_val = calculate_qi_gain(target_stage_idx)
    
    # 5. 生成选项效果
    effect_a = build_effect(template["choice_a_logic"], qi_val, target_stage_idx)
    effect_b = build_effect(template["choice_b_logic"], qi_val, target_stage_idx)
    
    # 6. 润色按钮文字
    btn_a_final = polish_choice_text(btn_a_raw, template["choice_a_logic"])
    btn_b_final = polish_choice_text(btn_b_raw, template["choice_b_logic"])
    
    # 7. 组装对象
    event = {
        "id": f"evt_auto_{i+1:04d}",
        "title": title,
        "desc": full_desc,
        "rarity": "epic" if target_stage_idx >= 10 else ("rare" if target_stage_idx >= 5 else "common"),
        "minStage": STAGES[target_stage_idx],
        # maxStage 设为当前 + 2，防止筑基期遇到事件一直留到大乘期还在做
        "maxStage": STAGES[min(target_stage_idx + 2, 15)],
        "choices": [
            {
                "id": "a",
                "text": btn_a_final,
                "effect": effect_a
            },
            {
                "id": "b",
                "text": btn_b_final,
                "effect": effect_b
            }
        ]
    }
    
    events.append(event)

# --- 6. 写入文件 ---
file_path = "events.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"✅ 生成完毕！共 {len(events)} 个事件。")
print(f"   - 筑基收益: ~{calculate_qi_gain(0)}")
print(f"   - 元婴收益: ~{calculate_qi_gain(5)}")
print(f"   - 渡劫收益: ~{calculate_qi_gain(10)}")
print(f"   - 玄仙收益: ~{calculate_qi_gain(15)}")
