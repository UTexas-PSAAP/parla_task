from .task_wrappers import task, create_task, run_generation_task

from .gpu_map import bind_devices as _bind_devices, get_device

_bind_devices() 
