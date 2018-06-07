up:
	vagrant up \
	    --parallel

clean:
	vagrant stop -f
	vagrant destroy -f

.PHONY: up clean
