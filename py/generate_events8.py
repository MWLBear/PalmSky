import json
import random
import math

# 16 大境界
STAGES = [
    "筑基", "开光", "胎息", "辟谷",
    "金丹", "元婴", "出窍", "分神",
    "合体", "大乘", "渡劫", "地仙",
    "天仙", "金仙", "大罗金仙", "九天玄仙"
]

# --- 文案库 ---
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
ACTION_B_LOW = ["无视", "离开", "绕路", "放弃", "不予理会"]

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
ACTION_B_MID = ["谨慎退去", "不沾因果", "远远观望", "转身离开"]

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
ACTION_B_HIGH = ["不敢染指", "顺其自然", "敬而远之", "迅速遁走"]

# --- 模板 ---
EVENT_TEMPLATES = [
    {   # Index 0: 纯收益
        "type": "pure_gain",
        "desc_suffix": " 机缘已至。",
        "choice_a_logic": "gain_standard",
        "choice_b_logic": "nothing"
    },
    {   # Index 1: 风险博弈
        "type": "risk_reward",
        "desc_suffix": " 福祸相依。",
        "choice_a_logic": "gain_or_lose",
        "choice_b_logic": "nothing"
    },
    {   # Index 2: Buff (加速)
        "type": "buff_time",
        "desc_suffix": " 稍纵即逝！",
        "choice_a_logic": "buff_auto",
        "choice_b_logic": "gain_tap_buff"
    },
    {   # Index 3: 道具 (保命)
        "type": "item_reward",
        "desc_suffix": " 似有宝光。",
        "choice_a_logic": "grant_item",
        "choice_b_logic": "nothing"
    }
]

# --- 辅助函数 ---

def get_random_text(stage_idx):
    if stage_idx <= 3:
        item = random.choice(DATA_LOW)
        subject = item["sub"]
        action_a = random.choice(item["acts"])
        prefix = random.choice(PREFIX_LOW)
        action_b = random.choice(ACTION_B_LOW)
        title = f"{prefix}{subject}"
        base_desc = f"偶遇{title}。"
    elif stage_idx <= 9:
        item = random.choice(DATA_MID)
        subject = item["sub"]
        action_a = random.choice(item["acts"])
        prefix = random.choice(PREFIX_MID)
        action_b = random.choice(ACTION_B_MID)
        title = f"{prefix}{subject}"
        base_desc = f"前方出现{title}。"
    else:
        item = random.choice(DATA_HIGH)
        subject = item["sub"]
        action_a = random.choice(item["acts"])
        prefix = random.choice(PREFIX_HIGH)
        action_b = random.choice(ACTION_B_HIGH)
        title = f"{prefix}{subject}"
        base_desc = f"触碰到了{title}。"
    return title, base_desc, action_a, action_b

def calculate_qi_gain(stage_idx):
    # 1.8 指数增长
    if stage_idx <= 3: base = 120; growth = 1.6
    elif stage_idx <= 9: base = 500; growth = 1.9
    else: base = 8000; growth = 2.4
    val = base * math.pow(growth, stage_idx)
    random_factor = random.uniform(0.8, 1.2)
    final_val = int(val * random_factor)
    if final_val > 10000: return (final_val // 100) * 100
    return (final_val // 10) * 10

def build_effect(logic_type, qi_base, stage_idx):
    if logic_type == "nothing": return {"type": "nothing"}
    if logic_type == "gain_standard": return {"type": "gain_qi", "value": qi_base}
    
    if logic_type == "gain_or_lose":
        if random.random() < 0.6: return {"type": "gain_qi", "value": qi_base}
        else: return {"type": "lose_qi", "value": int(qi_base * 0.5)}
        
    if logic_type == "buff_auto":
        # 30-120秒，倍率高
        duration = 60 if stage_idx < 10 else 120
        value = 0.8 if stage_idx < 10 else 1.0
        return {"type": "gain_auto_temp", "value": value, "duration": duration}
        
    if logic_type == "gain_tap_buff":
        if stage_idx >= 5:
            duration = 30 if stage_idx < 10 else 60
            return {"type": "gain_tap_ratio_temp", "value": 1.5, "duration": duration}
        else: return {"type": "nothing"}
        
    if logic_type == "grant_item":
        return {"type": "grant_item", "value": None}
        
    return {"type": "nothing"}

def polish_choice_text(text, logic_type):
    if logic_type == "gain_or_lose": return f"{text} (博)"
    if logic_type == "buff_auto" or logic_type == "gain_tap_buff": return f"{text} (增益)"
    if logic_type == "grant_item": return f"{text} (夺宝)"
    return text

def get_weights_by_stage(stage_idx):
    # [纯收益, 风险, Buff, 道具]
    if stage_idx <= 3: return [50, 20, 25, 5]
    elif stage_idx <= 9: return [40, 25, 20, 15]
    else: return [25, 35, 10, 30]

# --- 5. 金字塔生成逻辑 ---

events = []
global_id_counter = 1

# 遍历所有 16 个境界
for stage_idx in range(16):
    
    # 🌟 金字塔数量分布策略 🌟
    if stage_idx <= 3:      # 筑基-辟谷 (前期)
        count = 50          # 停留短，事件少
    elif stage_idx <= 7:    # 金丹-分神 (中期)
        count = 100         # 停留中等
    elif stage_idx <= 11:   # 合体-地仙 (后期)
        count = 150         # 停留长
    else:                   # 天仙-玄仙 (终局)
        count = 200         # 停留非常长，需要大量内容
        
    # 为当前境界生成指定数量
    for _ in range(count):
        weights = get_weights_by_stage(stage_idx)
        template = random.choices(EVENT_TEMPLATES, weights=weights, k=1)[0]
        
        title, desc_base, btn_a_raw, btn_b_raw = get_random_text(stage_idx)
        full_desc = desc_base + template["desc_suffix"]
        qi_val = calculate_qi_gain(stage_idx)
        
        effect_a = build_effect(template["choice_a_logic"], qi_val, stage_idx)
        effect_b = build_effect(template["choice_b_logic"], qi_val, stage_idx)
        
        btn_a_final = polish_choice_text(btn_a_raw, template["choice_a_logic"])
        btn_b_final = polish_choice_text(btn_b_raw, template["choice_b_logic"])
        
        event = {
            "id": f"evt_pyramid_{global_id_counter:05d}",
            "title": title,
            "desc": full_desc,
            "rarity": "epic" if stage_idx >= 10 else ("rare" if stage_idx >= 5 else "common"),
            "minStage": STAGES[stage_idx],
            # 允许向上跨越 2 个境界，增加一点点随机性
            "maxStage": STAGES[min(stage_idx + 2, 15)],
            "choices": [
                { "id": "a", "text": btn_a_final, "effect": effect_a },
                { "id": "b", "text": btn_b_final, "effect": effect_b }
            ]
        }
        
        events.append(event)
        global_id_counter += 1

# --- 6. 写入 ---
file_path = "events.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"✅ [金字塔版] 生成完毕！共 {len(events)} 个事件。")
print(f"前期每级 50 个，后期每级 200 个，完美适配1年游玩时长。")
