conda activate minisweyibop
CUDA_VISIBLE_DEVICES=7,8 python -m vllm.entrypoints.openai.api_server \
  --model agentica-org/DeepSWE-Preview \
  --served-model-name DeepSWE-Preview \
  --port 8005 \
  --tensor-parallel-size 2


export OPENAI_API_BASE=http://127.0.0.1:8005/v1
export OPENAI_API_KEY=sk-local
mini-extra swebench \
  --model openai/DeepSWE-Preview \
  --config /home/haizhonz/yibop/mini-swe-agent/deepswe_model_config.yaml \
  --subset verified --split test \
  --workers 16 \
  -o runs/verified-test



CUDA_VISIBLE_DEVICES=8,9 python -m vllm.entrypoints.openai.api_server \
  --model moonshotai/Kimi-K2-Instruct \
  --served-model-name Kimi-K2-Instruct \
  --port 8006 \
  --tensor-parallel-size 2 \
  --trust-remote-code

CUDA_VISIBLE_DEVICES=6,7,8,9 python -m vllm.entrypoints.openai.api_server \
  --model moonshotai/Kimi-K2-Instruct \
  --served-model-name Kimi-K2-Instruct \
  --port 8006 \
  --tensor-parallel-size 4 \
  --trust-remote-code


export OPENAI_API_BASE=http://127.0.0.1:8005/v1
export OPENAI_API_KEY=sk-local
export LITELLM_MODEL_REGISTRY_PATH=/home/haizhonz/yibop/mini-swe-agent/custom_model_registry.json


mini-extra swebench \
--config ~/yibop/mini-swe-agent/deepswe_model_config.yaml \
--subset verified --split test \
--workers 1 \
-o runs/verified-test


CUDA_VISIBLE_DEVICES=6,7 python -m vllm.entrypoints.openai.api_server \
  --model moonshotai/Kimi-K2-Instruct \
  --served-model-name Kimi-K2-Instruct \
  --port 8006 \
  --tensor-parallel-size 2

export OPENAI_API_BASE=http://127.0.0.1:8005/v1
export OPENAI_API_KEY=sk-local
mini-extra swebench \
  --model openai/DeepSWE-Preview \
  --config /home/haizhonz/yibop/mini-swe-agent/deepswe_model_config.yaml \
  --subset verified --split test \
  --workers 16 \
  -o runs/verified-test


# 创建会话并在 pane 1 启动 vLLM
tmux new -s deepswe -d
tmux send-keys -t deepswe '
eval "$(conda shell.bash hook)";
conda activate minisweyibop;
CUDA_VISIBLE_DEVICES=7,8 python -m vllm.entrypoints.openai.api_server \
  --model agentica-org/DeepSWE-Preview \
  --served-model-name DeepSWE-Preview \
  --port 8005 \
  --tensor-parallel-size 2 2>&1 | tee runs/vllm_8005.log' C-m

# 新 pane 跑评测（自动等待服务就绪）
tmux split-window -t deepswe -v
tmux send-keys -t deepswe.1 '
eval "$(conda shell.bash hook)";
conda activate minisweyibop;
export OPENAI_API_BASE=http://127.0.0.1:8005/v1;
export OPENAI_API_KEY=sk-local;
until curl -sSf http://127.0.0.1:8005/v1/models >/dev/null; do echo "[wait] vLLM..."; sleep 2; done;
mini-extra swebench \
  --model openai/DeepSWE-Preview \
  --config /home/haizhonz/yibop/mini-swe-agent/deepswe_model_config.yaml \
  --subset verified --split test \
  --workers 16 \
  -o runs/verified-test 2>&1 | tee runs/swebench_verified_test.log' C-m

# 立刻接入（或稍后用 tmux attach -t deepswe）
tmux attach -t deepswe
