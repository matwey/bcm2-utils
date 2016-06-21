#ifndef BCM2DUMP_PS_H
#define BCM2DUMP_PS_H
#include <string>

namespace bcm2dump {

class ps_header
{
	public:
	struct raw
	{
		uint16_t signature;
		uint16_t control;
		uint16_t ver_maj;
		uint16_t ver_min;
		uint32_t timestamp;
		uint32_t length;
		uint32_t loadaddr;
		char filename[48];
		char pad[8];
		uint32_t length1;
		uint32_t length2;
		uint16_t hcs;
		uint16_t reserved;
		uint32_t crc;
	} __attribute__((__packed__));

	static_assert(sizeof(raw) == 92, "unexpected raw header size");

	static uint16_t constexpr c_comp_none = 0;
	static uint16_t constexpr c_comp_lz = 1;
	static uint16_t constexpr c_comp_mini_lzo = 2;
	static uint16_t constexpr c_comp_reserved = 3;
	static uint16_t constexpr c_comp_nrv2d99 = 4;
	static uint16_t constexpr c_comp_lza = 5;
	static uint16_t constexpr c_dual_files = 0x100;

	ps_header(const std::string& buf)
	{ parse(buf); }
	ps_header(const ps_header& other) = default;
	ps_header(ps_header&& other) = default;

	ps_header& parse(const std::string& buf);

	bool hcs_valid() const
	{ return m_valid; }

	std::string filename() const;

	uint16_t signature() const
	{ return m_raw.signature; }

	uint32_t length() const
	{ return m_raw.length; }

	uint16_t compression() const
	{ return m_raw.control & 0x7; }

	bool is_dual() const
	{ return m_raw.control & c_dual_files; }

	private:
	bool m_valid = false;
	raw m_raw;
};
}
#endif