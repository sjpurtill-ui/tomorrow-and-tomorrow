# Opens the simulator bench (tools/sim/bench.py) in the browser: set the numbers,
# run the fast sim, compare runs. It never touches the game or its saves.
#   powershell -ExecutionPolicy Bypass -File tools\sim_bench.ps1 [-Port 8765]
param([int]$Port = 8765)
$bench = Join-Path $PSScriptRoot "sim\bench.py"
python $bench --port $Port
