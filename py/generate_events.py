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

# 词库：前期 (0-3 索引)
PREFIX_LOW = ["残破的", "普通的", "路边的", "山间的", "神秘的", "微弱的", "凡尘的", "荒废的"]
SUBJECT_LOW = ["灵泉", "石碑", "野兽", "灵草", "洞府", "行脚商", "猎户", "野果", "寒潭", "断剑"]
ACTION_LOW_A = ["取走", "感悟", "击杀", "采集", "探索", "交易", "帮助", "食用", "清洗", "拾取"]
ACTION_LOW_B = ["无视", "离开", "绕路", "放弃", "不予理会", "谨慎观望"]

# 词库：中期 (4-9 索引)
PREFIX_MID = ["上古", "宗门", "千年", "狂暴的", "奇异的", "禁制的", "魔化的", "纯净的"]
SUBJECT_MID = ["秘境", "长老", "妖兽", "灵脉", "雷劫", "心魔", "阵法", "丹炉", "残魂", "剑意"]
ACTION_MID_A = ["强行破除", "虚心请教", "斩杀证道", "吸纳灵气", "引雷淬体", "坚守道心", "入阵参悟", "开炉炼丹", "搜魂", "观摩"]

# 词库：后期 (10-15 索引)
PREFIX_HIGH = ["太古", "虚空", "天道", "混沌", "不朽", "灭世", "真龙", "星辰", "法则", "鸿蒙"]
SUBJECT_HIGH = ["裂缝", "法则", "神雷", "遗蜕", "长河", "本源", "古神", "仙宫", "魔域", "因果"]
ACTION_HIGH_A = ["以身合道", "吞噬本源", "硬抗天威", "祭拜", "逆流而上", "炼化", "论道", "入主", "镇压", "斩断"]

# --- 2. 辅助函数 ---

def get_random_text(stage_idx):
    """根据境界索引返回合适的文本组合"""
    if stage_idx <= 3: # 前期
        title = f"{random.choice(PREFIX_LOW)}{random.choice(SUBJECT_LOW)}"
        desc = f"你在游历途中，偶然发现了{title}，似乎有些机缘。"
        choice_a = random.choice(ACTION_LOW_A)
        choice_b = random.choice(ACTION_LOW_B)
    elif stage_idx <= 9: # 中期
        title = f"{random.choice(PREFIX_MID)}{random.choice(SUBJECT_MID)}"
        desc = f"修行至此，忽生感应，前方出现{title}，散发着惊人的波动。"
        choice_a = random.choice(ACTION_MID_A)
        choice_b = random.choice(ACTION_LOW_B)
    else: # 后期
        title = f"{random.choice(PREFIX_HIGH)}{random.choice(SUBJECT_HIGH)}"
        desc = f"触碰到了一丝{title}的气息，这是通往大道的契机。"
        choice_a = random.choice(ACTION_HIGH_A)
        choice_b = "不敢染指"
    
    return title, desc, choice_a, choice_b

def calculate_qi_gain(stage_idx):
    """
    根据境界计算灵气数值 (数值膨胀逻辑)
    公式：基础值 * (1.8 ^ 境界索引)
    """
    base = 100
    multiplier = 1.8 # 指数增长系数
    val = base * math.pow(multiplier, stage_idx)
    
    # 加上一点随机波动 (±20%)
    random_factor = random.uniform(0.8, 1.2)
    final_val = int(val * random_factor)
    
    # 取整稍微好看点
    return (final_val // 10) * 10

# --- 3. 生成逻辑 ---

events = []

for i in range(TOTAL_EVENTS):
    # 1. 随机确定这个事件所属的境界 (均匀分布)
    # 或者可以使用加权随机，让中期事件更多
    target_stage_idx = random.randint(0, 15)
    
    stage_name = STAGES[target_stage_idx]
    
    # 2. 确定 maxStage (通常是当前境界 + 1 或 2，防止高等级遇到太低级的)
    max_stage_idx = min(target_stage_idx + 2, 15)
    max_stage_name = STAGES[max_stage_idx]
    
    # 3. 获取文本
    title, desc, btn_a, btn_b = get_random_text(target_stage_idx)
    
    # 4. 计算数值
    qi_value = calculate_qi_gain(target_stage_idx)
    
    # 5. 随机决定类型 (80% 加灵气，10% 扣灵气，5% 道具，5% buff)
    rand_type = random.random()
    effect = {}
    
    if rand_type < 0.7: # 加灵气 (最常见)
        effect = {"type": "gain_qi", "value": qi_value}
    elif rand_type < 0.8: # 扣灵气 (风险)
        # 扣除是获得的 50%
        effect = {"type": "lose_qi", "value": int(qi_value * 0.5)}
        desc += " 但似乎伴随着巨大的风险。"
    elif rand_type < 0.9: # 获得道具
        effect = {"type": "grant_item", "value": None}
        btn_a = "收入囊中"
    else: # Buff
        effect = {"type": "gain_auto_temp", "value": 0.5, "duration": 300}
        btn_a = "感悟修炼"

    # 6. 构建对象
    event = {
        "id": f"evt_gen_{i+1:03d}",
        "title": title,
        "desc": desc,
        "rarity": "common" if target_stage_idx < 5 else ("rare" if target_stage_idx < 10 else "epic"),
        "minStage": stage_name,
        "maxStage": max_stage_name,
        "choices": [
            {
                "id": "a",
                "text": btn_a,
                "effect": effect
            },
            {
                "id": "b",
                "text": btn_b,
                "effect": {"type": "nothing"}
            }
        ]
    }
    
    events.append(event)

# --- 4. 写入文件 ---
file_path = "events.json"
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)

print(f"✅ 成功生成 {len(events)} 个修仙事件，已保存至 {file_path}")
print(f"   - 筑基期收益示例: {calculate_qi_gain(0)}")
print(f"   - 元婴期收益示例: {calculate_qi_gain(5)}")
print(f"   - 渡劫期收益示例: {calculate_qi_gain(10)}")
print(f"   - 玄仙期收益示例: {calculate_qi_gain(15)}")
