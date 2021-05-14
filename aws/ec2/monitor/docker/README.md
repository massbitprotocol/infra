# Geth prometheus metrics

Collect and visualize [geth](https://github.com/ethereum/go-ethereum) metrics with prometheus and grafana.


Available in geth with [commit](https://github.com/ethereum/go-ethereum/commit/31bc2a2434ed29b6cd020ee712722b4b865f32e1). 
Expected release verion: `v1.9.0`
Last `chapsuk/geth:prometheus` docker image [commit](https://github.com/ethereum/go-ethereum/commit/26b50e3ebe3be197c68763e71e41926ed7df0863).

## Config
Modify prometheus.yml config to point to your Geth Server 
```
  static_configs:
  - targets:
    - bsc-treenode.massbit.io:6060
```

## Run

```bash
> docker-compose up -d
```

## Dashboard

![Dashboard Screenshot](screen.png)