"""Build the research report from archived solver results, without rerunning models.

Requires numpy, matplotlib, reportlab; pymupdf is used for optional PDF inspection.
Run: python validation/research_report.py
"""
from pathlib import Path
import csv
import hashlib
import itertools
import json
import html
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / 'validation/results'
OUT = ROOT / 'validation/research_report'
FIG = OUT / 'figures'
FIG.mkdir(parents=True, exist_ok=True)
NAMES = ['IsochronousControl', 'PermanentDroopControl', 'TransientDroopControl', 'AGCControl', 'FCRControl']
LABELS = ['Isochronous', 'Permanent droop', 'Transient droop', 'AGC + droop', 'FCR']
COLORS = ['#1479b8', '#ce6b12', '#218355', '#844cb0', '#c03748']
plt.rcParams.update({'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False,
                     'axes.labelcolor': '#263642', 'text.color': '#263642', 'savefig.facecolor': 'white'})


def read(path):
    with path.open() as f:
        rows = list(csv.DictReader(f))
    return {k: np.array([float(r[k]) for r in rows]) for k in rows[0]}


def save(fig, name):
    fig.savefig(FIG / (name + '.png'), dpi=200, bbox_inches='tight')
    fig.savefig(FIG / (name + '.svg'), bbox_inches='tight')
    plt.close(fig)


def decorate(ax, ylabel, xlabel='Time (s)'):
    ax.set(xlabel=xlabel, ylabel=ylabel)
    ax.grid(alpha=.2)


def settle(t, f, target):
    mask = t >= 50
    t, f = t[mask], f[mask]
    bad = np.flatnonzero(abs(f-target) > .01)
    if not len(bad):
        return 0.0
    i = bad[-1]+1
    return None if i == len(t) else float(t[i]-50)


def main():
    hashes = json.loads((RESULTS / 'source_sha256.json').read_text())
    for path, expected in hashes.items():
        assert hashlib.sha256((ROOT/path).read_bytes().replace(b'\r\n', b'\n')).hexdigest() == expected, 'Source changed: '+path
    data = {n: read(RESULTS / (n+'.csv')) for n in NAMES}
    metrics = []
    for n, label in zip(NAMES, LABELS):
        d = data[n]
        t, f = d['time'], d['frequency']
        target = 50 if n in ['IsochronousControl', 'AGCControl'] else 49.9 if 'Droop' in n else f[-1]
        common = (t >= 50) & (t <= 300)
        i = np.argmin(f)
        metrics.append({'model':n, 'label':label, 'nadir_Hz':float(f[i]),
                        'time_to_nadir_s':float(t[i]-50), 'final_Hz':float(f[-1]),
                        'target_Hz':float(target), 'settling_10mHz_s':settle(t,f,target),
                        'nominal_recovery_10mHz_s':settle(t,f,50),
                        'IAE_250s_Hz_s':float(np.trapezoid(abs(f[common]-50),t[common])),
                        'duration_s':float(t[-1])})
    (OUT/'metrics.json').write_text(json.dumps(metrics, indent=2)+'\n')
    with (OUT/'metrics.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(metrics[0]));w.writeheader();w.writerows(metrics)

    # Actual imposed load, not an illustrative signal.
    d=data['IsochronousControl']
    fig, ax=plt.subplots(figsize=(9,2.5),layout='constrained')
    ax.plot(d['time'],d['load.y']/1e6,lw=2.4,color='#263642')
    ax.axvline(50,color='#9ba8af',ls='--')
    ax.annotate('+5 MW = 5% of 100 MW base\n10% of initial 50 MW demand',xy=(50,52.5),xytext=(105,51.3),
                arrowprops={'arrowstyle':'->','color':'#263642'},fontsize=11)
    ax.set(ylim=(49,56),xlim=(0,300),yticks=[50,55])
    decorate(ax,'Electrical load (MW)');save(fig,'load_step_input')

    # Architecture diagram describes the boundary; it is not an OMEdit screenshot.
    fig,ax=plt.subplots(figsize=(10,4.0));ax.set(xlim=(0,10),ylim=(0,4));ax.axis('off')
    def box(x,y,w,h,s,c='#e9f2f8'):
        ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle='round,pad=0.035',facecolor=c,edgecolor='#608398'))
        ax.text(x+w/2,y+h/2,s,ha='center',va='center',fontsize=10)
    def arrow(a,b):
        ax.annotate('',xy=b,xytext=a,arrowprops={'arrowstyle':'->','color':'#263642','lw':1.4})
    box(.2,2.9,1.3,.65,'Reservoir')
    box(1.9,2.9,1.3,.65,'Penstock')
    box(3.6,2.9,1.3,.65,'Turbine')
    box(5.4,2.9,1.65,.65,'Generator\nH = 4 s')
    box(8,2.9,1.65,.65,'Load / 0.99\n50 to 55 MW','#fcf0e5')
    for a,b in [((1.5,3.23),(1.9,3.23)),((3.2,3.23),(3.6,3.23)),((4.9,3.23),(5.4,3.23)),((8,3.23),(7.05,3.23))]:arrow(a,b)
    box(3.6,1.55,1.3,.65,'Gate\nactuator')
    box(5.4,1.55,1.65,.65,'Primary\ngovernor')
    box(8,1.55,1.65,.65,'Frequency\npu to Hz')
    arrow((5.4,1.88),(4.9,1.88));arrow((4.25,2.2),(4.25,2.9))
    arrow((8,1.88),(7.05,1.88));arrow((7.05,2.9),(8.4,2.2))
    box(5.4,.2,1.65,.65,'Secondary AGC\noptional','#f1eaf7')
    arrow((6.22,.85),(6.22,1.55));arrow((8.8,1.55),(7.05,.52))
    ax.text(.2,2.28,'Water exits turbine to tailwater.\nMechanical shaft couples turbine and generator.',fontsize=9)
    ax.text(.2,.55,'Additional feedback: actual gate position;\npower feedback for droop control.\nOne isolated unit; no tie line or external grid.',fontsize=9)
    save(fig,'system_design')

    fig,axes=plt.subplots(1,2,figsize=(10,3.4),layout='constrained')
    for n,label,color in zip(NAMES,LABELS,COLORS):
        d=data[n]
        for ax in axes:ax.plot(d['time'],d['frequency'],label=label,color=color,lw=1.6)
    axes[0].set(xlim=(45,100),title='Early response')
    axes[1].set(xlim=(0,300),title='First 300 seconds')
    for ax in axes:decorate(ax,'Frequency (Hz)')
    axes[1].legend(fontsize=8,loc='lower right');save(fig,'frequency_response')

    fig,axes=plt.subplots(2,1,figsize=(9,5),layout='constrained',sharex=True)
    for n,label,color in zip(NAMES,LABELS,COLORS):
        d=data[n];axes[0].plot(d['time'],d['electricalGeneration']/1e6,label=label,color=color,lw=1.5)
        axes[1].plot(d['time'],d['actuator.y'],color=color,lw=1.5)
    d=data['IsochronousControl'];axes[0].plot(d['time'],d['load.y']/1e6,'--',color='black',label='Demand')
    axes[0].legend(ncol=3,fontsize=8);decorate(axes[0],'0.99 x turbine power (MW)')
    decorate(axes[1],'Gate opening (pu)');axes[1].set_xlim(45,150);save(fig,'power_gate_response')

    d=data['AGCControl']
    fig,axes=plt.subplots(1,2,figsize=(10,3.2),layout='constrained')
    axes[0].plot(d['time']/60,d['frequency'],color=COLORS[3]);decorate(axes[0],'Frequency (Hz)','Time (min)')
    axes[0].set_title('Full secondary recovery')
    axes[1].semilogy(d['time']/60,np.maximum(abs(d['frequency']-50),1e-8),color=COLORS[3])
    axes[1].axhline(.01,color='#263642',ls='--',label='10 mHz analysis band')
    decorate(axes[1],'Absolute frequency error (Hz)','Time (min)');axes[1].legend(fontsize=8)
    axes[1].set(xlim=(1,134),ylim=(1e-4,2));save(fig,'agc_recovery')

    d=read(RESULTS/'FCRStepTest.csv')
    fig,axes=plt.subplots(1,2,figsize=(10,3),layout='constrained')
    axes[0].plot(d['time'],d['frequencyInput'],color='#263642');decorate(axes[0],'Imposed frequency (Hz)')
    axes[1].plot(d['time'],d['deliveredReserve'],color=COLORS[4]);axes[1].axhline(.09,ls='--',color='#8d969c')
    decorate(axes[1],'Additional gate opening (pu)')
    axes[0].set_xlim(15,35);axes[1].set_xlim(19,27);save(fig,'fcr_controller_step')

    # Explicit proposed DOE. Five entries reuse archived baseline simulations.
    experiments=[]
    def add(stage,n,p=50,dp=5,H=4,extra=None):
        pars={'P_load0':p*1e6,'dP':dp*1e6,'H':H};pars.update(extra or {})
        existing=stage=='Robustness' and p==50 and dp==5 and H==4
        experiments.append({'id':f'E{len(experiments)+1:03d}','stage':stage,'model':'OpenHPLTest.NewTest.'+n,
                            'status':'completed baseline reused' if existing else 'planned not run',
                            'stop_s':8000 if n=='AGCControl' else 300,
                            'parameters':json.dumps(pars,sort_keys=True)})
    for n,p,dp,H in itertools.product(NAMES,[30,50,70],[-5,1,5],[2,4,6]):add('Robustness',n,p,dp,H)
    for n in NAMES:add('Zero disturbance',n,dp=0)
    for n,R,p,dp in itertools.product(['PermanentDroopControl','TransientDroopControl'],[.02,.04,.06],[30,70],[-5,5]):
        add('Droop sensitivity',n,p,dp,extra={'R':R})
    for n,kp,ki in itertools.product(NAMES[:3],[1,2,4],[.05,.1,.2]):
        add('Primary gain screening',n,extra={'governor.Kp':kp,'governor.Ki':ki})
    for ki in [.01,.02,.04]:add('Secondary gain screening','AGCControl',extra={'Ki_AGC':ki})
    assert len(experiments)==194
    with (OUT/'experiment_matrix.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(experiments[0]));w.writeheader();w.writerows(experiments)

    source_urls={
        'requirements':'https://www.statnett.no/globalassets/for-aktorer-i-kraftsystemet/marked/reservemarkeder/fcr/pq-dokumenter/technical-requirements-for-frequency-containment-reserve-provision-in-the-nordic-synchronous-area.pdf',
        'test_program':'https://www.statnett.no/globalassets/for-aktorer-i-kraftsystemet/marked/reservemarkeder/fcr/pq-dokumenter/test-program-for-prequalification-of-fcr-in-the-nordic-synchronous-area-v2025-03-28.pdf',
    }
    (OUT/'references.json').write_text(json.dumps(source_urls,indent=2)+'\n')
    used=list(RESULTS.glob('*.csv'))+[RESULTS/'source_sha256.json',RESULTS/'summary.json']
    (OUT/'input_sha256.json').write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in used},indent=2)+'\n')

    # One content model generates both editable repository documentation and PDF.
    pages=[]
    def page(title):
        pages.append([('heading',title)])
    def p(text):pages[-1].append(('p',text))
    def img(name,caption):pages[-1].append(('image',(name,caption)))
    def table(headers,rows,widths):pages[-1].append(('table',(headers,rows,widths)))
    page('OpenHPL hydropower control step response study')
    p('Research and technical review briefing | 26 September 2026 | Local simulation evidence')
    p('OpenHPLTest.NewTest provides a working nonlinear hydropower test bed for studying primary frequency control and secondary restoration. The completed tests reproduce the expected permanent-droop equilibrium and isochronous recovery. The present tuning produces sizeable frequency dips and slow secondary recovery; it is a starting point for research and discussion with Statnett, not an approved reserve-delivery model.')
    img('system_design','Figure 1. Conceptual architecture of the connected single-unit experiments. The diagram summarizes signal and physical connections; it is not a native Modelica rendering.')
    table(['Plant quantity','Baseline value'],[
        ['Frequency / power base','50 Hz / 100 MW'],['Initial demand / change','50 MW / +5 MW at 50 s'],
        ['Inertia / electrical efficiency','H = 4 s / 0.99'],['Penstock / nominal turbine head','600 m long, 4 m diameter, 300 m drop / 345 m'],
        ['Reservoir and tailwater levels','50 m and 5 m, both held constant'],['Gate position / rate limits','0.01 to 1 pu / +/-0.05 pu/s']], [170,325])
    p('The generator carries the total inertia; turbine inertia is zero to avoid duplication. Initial hydraulic flow, gate position and shaft power balance are solved at equilibrium. The current boundary has no electrical network, load-frequency damping, tie line, voltage-control loop or multi-unit sharing.')

    page('Load disturbance and primary frequency response')
    img('load_step_input','Figure 2. Actual archived electrical-load signal: 50 MW before 50 s and 55 MW thereafter. The same step is applied to all five main control architectures.')
    img('frequency_response','Figure 3. Measured simulated frequency. The AGC trace is shown only over the first 300 s here; its full run is 8000 s. Different gains and feedback structures prevent an equal-tuning ranking.')
    table(['Controller','Nadir Hz','Final Hz','End s'],[[m['label'],f"{m['nadir_Hz']:.4f}",f"{m['final_Hz']:.5f}",str(int(m['duration_s']))] for m in metrics],[200,95,110,90])
    p('Load increases before hydraulic power can respond. Rotor kinetic energy initially supplies the deficit, so speed falls. The governor opens the gate and turbine power catches up. The PI-based cases reach nadirs of 48.858 to 48.972 Hz; the more aggressive proportional FCR setting reaches 49.619 Hz and shows damped oscillation.')

    page('Hydraulic power delivery and gate motion')
    img('power_gate_response','Figure 4. Turbine power expressed on an electrical-equivalent basis and actual gate motion. The plotted supply is 0.99 times turbine shaft power, not independently measured electrical export.')
    p('During acceleration, turbine delivery exceeds shaft demand and replenishes rotor kinetic energy. Consequently, the orange or blue supply overshoot is not evidence of extra electrical export to a grid. The imposed electrical load is the dashed line. At equilibrium, electrical-equivalent turbine delivery reaches 55 MW in every case.')
    p('The final gate opening is approximately 0.49707 pu, compared with about 0.45183 pu initially. All hydraulic examples remain inside the position and rate limits. FCR approaches the 0.05 pu/s rate limit; the PI-governor cases use approximately 0.009 to 0.011 pu/s. These numbers describe this operating point only.')
    p('At unsaturated equilibrium the permanent-droop error is zero: (50 - f)/50 = R (P - P_ref)/P_base. With R = 0.04 and a 5 MW increment on 100 MW, the expected final frequency is 49.9 Hz. Transient droop adds Rt(gate - z), with Tr dz/dt = gate - z; this contribution vanishes at equilibrium, leaving the same offset.')
    p('The current transient-droop settings produce a slightly deeper nadir than permanent droop. This result does not establish that transient droop is inferior: its washout gain and time constant have not been optimized, and the controllers have not been matched for bandwidth or control effort.')

    page('Secondary recovery and quantitative response metrics')
    img('agc_recovery','Figure 5. AGC eventually restores nominal frequency. The logarithmic error plot exposes the long recovery hidden by a narrow linear frequency scale.')
    p('SecondaryAGC integrates per-unit frequency error and changes the primary power reference: dx/dt = Ki (50 - f)/50, P_ref = P_schedule + P_base clip(x). The present Ki is 0.02 per second. Final frequency is 49.999862 Hz at 8000 s. This is an isolated-area frequency integrator; it has no tie-line ACE or external automatic reserve activation interface.')
    table(['Controller','Nadir after step s','Settle to target s','IAE Hz s'],[[m['label'],f"{m['time_to_nadir_s']:.1f}",'-' if m['settling_10mHz_s'] is None else f"{m['settling_10mHz_s']:.1f}",f"{m['IAE_250s_Hz_s']:.2f}"] for m in metrics],[165,110,115,105])
    p('Settling means the first sampled time after which frequency remains within +/-0.01 Hz of the target for the remainder of the recorded run. Targets are 50 Hz for isochronous and AGC, 49.9 Hz for both droop cases, and the measured final frequency for FCR. Settling to an offset is not restoration to nominal frequency. Durations in this table start at the load step.')
    p('IAE integrates absolute deviation from 50 Hz over the common 50 to 300 s window. Nadirs and settling times are sample-based: 0.1 s output for primary cases and 1 s for AGC. The 10 mHz band is an analyst-selected research metric, not a Statnett acceptance threshold. Repeated deterministic runs do not provide statistical confidence intervals.')

    page('FCR component tests and relevance to Statnett')
    img('fcr_controller_step','Figure 6. Separate controller-only test: frequency is imposed from 50 to 49.8 Hz at 20 s. Additional gate opening reaches 0.1 pu; the archived event metric gives 90% activation after 1.972 s.')
    p('This 1.972 s result is gate-actuator performance, not a 90% MW reserve-delivery time. The test omits the waterway and generator. The hydraulic FCR example includes them, but excites an islanded load step rather than a prescribed grid-frequency test. The existing single-frequency sine harness is likewise exploratory.')
    p('The retrieved Nordic technical requirements are version 1.1 dated 28 March 2025. They address product response, stability, measurement, test conditions and data. Their FCR-N range is 49.9 to 50.1 Hz; FCR-D upward and downward operate in separate disturbance ranges. The current generic symmetric gate-gain block does not implement a selected product characteristic. [R1]')
    p('The accompanying test program specifies product-dependent step, ramp and sine tests. A single imposed step or one sine frequency does not cover that program. The prescribed sequence, amplitudes, durations and operating points must be selected for the intended product before assessing conformity. [R2]')
    p('For a Statnett discussion, this package can demonstrate architecture, traceable simulation evidence and a plan for model validation. It cannot yet substantiate contracted MW capacity, qualification, endurance or field performance. Gate reserve must be converted to calibrated active-power response across operating points, and a grid-connected or suitable frequency-injection plant harness must measure power at the relevant connection point.')
    p('Implementation gaps to address include product-specific activation logic, measurement delay/noise, realistic efficiency/head variation, power-capacity calibration and saturation recovery. FCR trackingCorrection is currently diagnostic only. SecondaryAGC limits its output but does not stop integrator windup; the baseline did not establish performance under prolonged saturation.')

    page('Completed experiments and proposed experimental design')
    table(['Completed family','Cases','Purpose'],[
        ['Main hydraulic controllers','5','Same +5 MW islanded load step'],
        ['HydraulicFCRTest and FCRComparison','2','FCR integration and response diagnostics'],
        ['FCRStepTest and FCRSineTest','2','Controller and actuator excitation']], [245,45,205])
    p('All nine existing examples completed using OpenModelica 1.26.0 with DASSL and 1e-7 tolerance. Modelica 4.1.0 was selected as compatible with requested 4.0.0. Numerical checks covered equilibrium startup, finite trajectories, gate limits, expected droop/recovery and final shaft balance. These checks are simulation verification, not validation against measurements.')
    table(['Proposed block','Factors and levels','Rows'],[
        ['Robustness factorial','5 controllers x P0 {30,50,70} MW x dP {-5,+1,+5} MW x H {2,4,6} s','135'],
        ['Zero-disturbance controls','One dP = 0 case for each controller at P0 = 50 MW and H = 4 s','5'],
        ['Droop sensitivity','2 droop controllers x R {2,4,6}% x P0 {30,70} MW x dP {-5,+5} MW','24'],
        ['Primary gain screening','3 PI governors x Kp {1,2,4} x Ki {0.05,0.1,0.2} per second','27'],
        ['Secondary gain screening','AGC Ki {0.01,0.02,0.04} per second at the baseline point','3']], [115,335,45])
    p('The machine-readable experiment_matrix.csv contains 194 design rows: five explicitly reuse completed baseline evidence and 189 are planned, not run. Some settings recur across blocks as cross-checks; these are design rows, not necessarily unique parameter combinations. The proposed levels are engineering screening choices, not Statnett-prescribed test points. Gain screening fixes the other baseline settings.')
    p('For every case, solve a fresh initial equilibrium, preserve the selected parameter set and record solver failures or limit violations as outcomes. Screen each operating point for feasible head, flow, speed and torque before interpreting results. Run primary cases for at least 300 s and AGC for at least 8000 s, extending censored cases when needed. Parameter overrides may require recompilation; the CSV is a design specification, not a batch runner.')

    page('Analysis protocol and next research decisions')
    p('Research question 1: Which architecture restores frequency, and which retains a predictable droop offset? Compare nadir, time to nadir, nominal-frequency error, target settling and common-window IAE. Verify analytical droop equilibrium separately from transient performance.')
    p('Research question 2: How sensitive is the response to inertia, initial loading and disturbance direction? The robustness factorial permits main-effect and interaction contrasts. Plot each factor against nadir, control effort and settling. Treat these as deterministic sensitivity results; do not attach statistical significance without an explicit uncertainty model.')
    p('Research question 3: Can tuning improve nadir without excessive gate movement or oscillation? Use the gain grid as screening, then select a small Pareto set balancing frequency deviation, gate total variation, peak gate rate and saturation duration. Compare designs at matched power-frequency slope or matched bandwidth before claiming one controller is better.')
    p('Use a two-stage workflow. First perform broad screening with the archived output resolution. Then rerun shortlisted and limiting cases at tighter tolerance (for example 1e-8) and 0.02 to 0.05 s output spacing around the disturbance. Inspect convergence of nadir, settling and peak rate; extend the simulation if settling is not demonstrated.')
    p('For physical validation, fit head-flow-power characteristics and actuator dynamics to documented plant measurements, retaining independent operating points for validation. Introduce measurement filtering, delays and any deadband/backlash supported by evidence. Only then add justified uncertainty ranges; a seeded ensemble or Latin-hypercube study can quantify uncertainty rather than treating arbitrary parameter sweeps as confidence bounds.')
    p('For product-oriented work, select FCR-N, FCR-D upward or FCR-D downward with the reviewer. Map the official test program to implementable frequency-injection scenarios and record the clause, signal, operating condition, measured power channel and acceptance calculation for each. Archive settings, raw time series, calibration and test report together. Confirm the applicable document revision before a formal campaign. [R1, R2]')
    p('Requested technical discussion: confirm the intended product and plant boundary, agree on the power measurement and baseline, identify operating-envelope data, and review the proposed test sequence. A subsequent multi-unit or two-area study will additionally require network/tie-line dynamics, participation factors and ACE; these are outside the current completed simulations.')

    page('Evidence provenance and references')
    p('The report uses the local archived simulation CSVs in validation/results. It does not claim additional experiments were run for this document. Before building, the report generator checks every recorded Modelica source hash against the current local package. input_sha256.json records the report input files; the model manifest is validation/results/source_sha256.json. The package was relocated to OpenHPLTest.NewTest without changing its equations, and all nine simulations were rerun under the new namespace.')
    p('Known solver messages: fixed-level reservoirs repeat their level constraints during initialization, which OpenModelica removes as redundant; one shaft reference angle is assigned an initial value. All runs initialized and completed. The package requests OpenIPSL 3.0.0, absent in the local environment; these examples do not instantiate it. Neither successful compilation nor these simplified physical assumptions establishes field validity.')
    table(['Artifact','Use'],[
        ['OpenHPLTest/NewTest','Modelica examples, controllers, signals and icons'],
        ['validation/load_step.py','Rerun nine examples and numerical checks'],
        ['validation/results/*.csv','Archived compact response data'],
        ['validation/research_report.py','Rebuild this report and figures'],
        ['research_report/experiment_matrix.csv','194 completed-reuse or planned design rows'],
        ['research_report/metrics.csv and metrics.json','Computed response metrics with explicit definitions'],
        ['research_report/figures/*.png and *.svg','Raster and vector figures for reuse']], [250,245])
    p('Reproduction: from the repository root, run python validation/load_step.py to produce a new solver run. A successful fresh run also updates the compact CSV archives and model manifest consumed by this report. Run python validation/research_report.py to regenerate this report from that evidence. Required report packages: numpy, matplotlib and reportlab.')
    p('R1. Nordic TSOs. Technical Requirements for Frequency Containment Reserve Provision in the Nordic Synchronous Area. Version 1.1, 28 March 2025. Relevant sections: 3 (products and performance), 4 (measurement), 5 (testing), 6 (data). Retrieved from Statnett on 25 September 2026.')
    pages[-1].append(('link',('Open technical requirements',source_urls['requirements'])))
    p('R2. Nordic TSOs. Test Program for Prequalification of FCR in the Nordic Synchronous Area. Statnett-hosted edition dated 28 March 2025. Relevant sections: 3 (FCR-N), 4 (dynamic FCR-D upward), 5 (dynamic FCR-D downward). Retrieved on 25 September 2026.')
    pages[-1].append(('link',('Open test program',source_urls['test_program'])))
    p('The analytical droop explanation follows the equations implemented in this package. No claim is made that the present blocks reproduce a particular published Kundur governor parameter set or a named plant. This briefing was prepared for potential research and TSO review; it has not been reviewed or endorsed by Statnett.')

    # Render report and Markdown from identical text, table rows and images.
    styles=getSampleStyleSheet()
    styles.add(ParagraphStyle(name='ReportBody',fontName='Helvetica',fontSize=9.5,leading=13.1,spaceAfter=9,textColor=colors.HexColor('#263642')))
    styles.add(ParagraphStyle(name='ReportHeading',fontName='Helvetica-Bold',fontSize=18,leading=22,spaceAfter=15,textColor=colors.black))
    styles.add(ParagraphStyle(name='ReportCaption',fontSize=8,leading=10,spaceAfter=10,textColor=colors.HexColor('#53616b')))
    styles.add(ParagraphStyle(name='Cell',fontSize=8.2,leading=10.5,spaceAfter=0))
    story=[];md=[]
    for idx,blocks in enumerate(pages):
        if idx:story.append(PageBreak())
        for kind,value in blocks:
            if kind=='heading':
                story.append(Paragraph(html.escape(value),styles['ReportHeading']));md.append(('# ' if idx==0 else '## ')+value+'\n')
            elif kind=='p':
                story.append(Paragraph(html.escape(value),styles['ReportBody']));md.append(value+'\n')
            elif kind=='link':
                title,url=value;story.append(Paragraph(f'<link href="{url}" color="#1479b8">{title}</link>',styles['ReportBody']));md.append(f'[{title}]({url})\n')
            elif kind=='image':
                name,caption=value
                from PIL import Image as PILImage
                path=FIG/(name+'.png')
                with PILImage.open(path) as im:w,h=im.size
                story.append(Image(str(path),width=495,height=495*h/w));story.append(Spacer(1,5))
                story.append(Paragraph(html.escape(caption),styles['ReportCaption']))
                md += [f'![{caption}](figures/{name}.png)\n',caption+'\n']
            elif kind=='table':
                headers,rows,widths=value
                cells=[[Paragraph(html.escape(str(c)),styles['Cell']) for c in row] for row in [headers]+rows]
                tab=Table(cells,colWidths=widths,repeatRows=1,hAlign='LEFT')
                tab.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#dceaf2')),
                    ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#f3f6f8')]),
                    ('GRID',(0,0),(-1,-1),.4,colors.HexColor('#d0d8dc')),('VALIGN',(0,0),(-1,-1),'MIDDLE'),
                    ('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]))
                story.extend([tab,Spacer(1,12)])
                md.append('| '+' | '.join(headers)+' |');md.append('| '+' | '.join(['---']*len(headers))+' |')
                md.extend('| '+' | '.join(map(str,row))+' |' for row in rows);md.append('')
    def footer(canvas,doc):
        canvas.setFont('Helvetica',8);canvas.setFillColor(colors.HexColor('#63717a'))
        canvas.drawString(50,28,'OpenHPLTest.NewTest | Simulation research briefing | 26 September 2026')
        canvas.drawRightString(A4[0]-50,28,str(doc.page))
    doc=SimpleDocTemplate(str(OUT/'OpenHPL_research_briefing.pdf'),pagesize=A4,leftMargin=50,rightMargin=50,topMargin=44,bottomMargin=46,
                         title='OpenHPL hydropower control step response study',author='OpenHPLTest.NewTest research documentation')
    doc.build(story,onFirstPage=footer,onLaterPages=footer)
    (OUT/'README.md').write_text('\n'.join(md),encoding='utf-8')
    print(json.dumps(metrics,indent=2))
    print('Report and 194-row experiment design created:',OUT)


if __name__=='__main__':
    main()
