package hash

// RedundancyType represents the redundancy algorithm type for object data.
type RedundancyType int32

const (
	RedundancyECType      RedundancyType = 0
	RedundancyReplicaType RedundancyType = 1
)
